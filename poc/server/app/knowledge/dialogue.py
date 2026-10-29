"""Walks through a scenario one instruction at a time.

The model never sees a whole procedure, only the task of the current turn: say this one
instruction. Inside a step the cursor moves by itself (the user's next words are taken as
"done"); between steps a short side call to the model picks the transition that the user's
answer satisfies. When the call gives no clear answer the cursor stays where it is: the
assistant repeats instead of guessing.

The cursor moves only after an answer was completed, so an interrupted answer is said again.
The state lives as long as the object, i.e. one WebSocket connection.
"""

import re
from dataclasses import dataclass

from app.knowledge.models import KnowledgeBase, Scenario, Step
from app.knowledge.prompts import ScenarioPrompts
from app.providers.base import LLMDone, LLMOptions, LLMProvider, Message

_USER_MESSAGES_FOR_ROUTING = 3
_DIGIT = re.compile(r"\W*(\d+)")


def _one_line(text: str) -> str:
    return " ".join(text.split())


def with_task(system_prompt: str, task: str) -> str:
    return f"{system_prompt.rstrip()}\n\n{task}"


@dataclass
class KnowledgeRuntime:
    kb: KnowledgeBase
    prompts: ScenarioPrompts

    def system_prompt(self, base: str) -> str:
        return with_task(base, self.prompts.rules.strip())

    def dialogue(self, llm: LLMProvider) -> "ScenarioDialogue":
        return ScenarioDialogue(self.kb, self.prompts, llm)


class ScenarioDialogue:
    def __init__(self, kb: KnowledgeBase, prompts: ScenarioPrompts, llm: LLMProvider) -> None:
        self._scenarios = {s.id: s for s in kb.scenarios}
        self._prompts = prompts
        self._llm = llm
        self._scenario: Scenario | None = None
        self._step: Step | None = None
        self._unit = 0  # index of the next thing to say in the step (see Step.units)
        self._advance_on_completion = False

    async def begin_turn(self, user_text: str, history: list[Message]) -> str:
        """Moves the cursor if the user's words call for it; returns the task for the model."""
        self._advance_on_completion = False
        if self._step is None:
            await self._choose_scenario(user_text, history)
        elif self._unit >= len(self._step.units) and self._step.transitions:
            await self._follow_transition(user_text, history)

        if self._step is None:
            titles = ", ".join(s.title for s in self._scenarios.values())
            return self._prompts.idle.format(titles=titles).strip()
        units = self._step.units
        if self._unit < len(units):
            self._advance_on_completion = True
            return self._prompts.say.format(instruction=units[self._unit]).strip()
        if not self._step.transitions:
            return self._prompts.finished.strip()
        return self._prompts.repeat.format(last=units[-1]).strip()

    def turn_completed(self) -> None:
        if self._advance_on_completion:
            self._unit += 1
        self._advance_on_completion = False

    async def _choose_scenario(self, user_text: str, history: list[Message]) -> None:
        scenarios = list(self._scenarios.values())
        user_messages = [m.content for m in history if m.role == "user"]
        recent = [*user_messages[-_USER_MESSAGES_FOR_ROUTING:], user_text]
        prompt = self._prompts.route_scenario.format(
            messages="\n".join(f"- {_one_line(t)}" for t in recent),
            options="\n".join(
                f"{i}. {s.title}: {_one_line(s.trigger)}" for i, s in enumerate(scenarios, 1)
            ),
        )
        choice = await self._choose(prompt, len(scenarios))
        if choice:
            self._enter(scenarios[choice - 1], scenarios[choice - 1].start)

    async def _follow_transition(self, user_text: str, history: list[Message]) -> None:
        assert self._step is not None
        transitions = self._step.transitions
        last_assistant = next((m.content for m in reversed(history) if m.role == "assistant"), "")
        prompt = self._prompts.route_step.format(
            assistant=_one_line(last_assistant),
            user=_one_line(user_text),
            options="\n".join(f"{i}. {_one_line(t.when)}" for i, t in enumerate(transitions, 1)),
        )
        choice = await self._choose(prompt, len(transitions))
        if not choice:
            return
        chosen = transitions[choice - 1]
        if chosen.goto is not None:
            assert self._scenario is not None
            self._enter(self._scenario, chosen.goto)
        elif chosen.handoff is not None:
            scenario_id, _, step_id = chosen.handoff.partition("/")
            self._enter(self._scenarios[scenario_id], step_id)

    def _enter(self, scenario: Scenario, step_id: str) -> None:
        self._scenario = scenario
        self._step = scenario.step(step_id)
        self._unit = 0

    async def _choose(self, prompt: str, options: int) -> int:
        """Asks the model for one digit; 0 means "none" and is also the answer to anything else."""
        text = ""
        messages = [Message(role="user", content=prompt)]
        async for event in self._llm.generate_stream(
            messages, LLMOptions(temperature=0.0, max_tokens=8)
        ):
            if isinstance(event, LLMDone):
                text = event.text
        match = _DIGIT.match(text)
        if match is None:
            return 0
        value = int(match.group(1))
        return value if value <= options else 0
