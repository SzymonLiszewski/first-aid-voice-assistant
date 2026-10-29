from collections.abc import AsyncIterator
from pathlib import Path
from typing import Any

from fastapi.testclient import TestClient

from app.knowledge import (
    KnowledgeRuntime,
    ScenarioDialogue,
    load_knowledge,
    load_scenario_prompts,
)
from app.main import create_app
from app.providers.base import LLMDelta, LLMDone, LLMEvent, LLMOptions, Message

KNOWLEDGE = Path("../../knowledge")
SCENARIO_PROMPTS = Path("prompts/scenario_v1.yaml")
BLS, CHOKING = "1", "2"  # alphabetical order of the scenario files, as the router lists them


class ScriptedLLM:
    """Returns the given replies one by one and records every prompt it got."""

    name = "scripted"

    def __init__(self, replies: list[str]) -> None:
        self.replies = list(replies)
        self.calls: list[list[Message]] = []

    async def generate_stream(
        self, messages: list[Message], opts: LLMOptions
    ) -> AsyncIterator[LLMEvent]:
        self.calls.append(messages)
        reply = self.replies.pop(0) if self.replies else ""
        yield LLMDelta(text=reply)
        yield LLMDone(text=reply)


def make(replies: list[str]) -> tuple[ScenarioDialogue, ScriptedLLM]:
    runtime = KnowledgeRuntime(load_knowledge(KNOWLEDGE), load_scenario_prompts(SCENARIO_PROMPTS))
    llm = ScriptedLLM(replies)
    return runtime.dialogue(llm), llm


async def turn(dialogue: ScenarioDialogue, text: str = "ok") -> str:
    task = await dialogue.begin_turn(text, [])
    dialogue.turn_completed()
    return task


async def test_first_turn_picks_the_scenario_and_gives_only_its_first_instruction() -> None:
    dialogue, llm = make([BLS])

    task = await dialogue.begin_turn("Kolega leży i się nie rusza", [])

    assert "Ty, poszkodowany i świadkowie" in task
    assert "potrząśnij" not in task
    assert len(llm.calls) == 1  # only the call that chose the scenario


async def test_scenario_choice_sees_the_recent_user_messages() -> None:
    dialogue, llm = make([BLS])
    history = [
        Message(role="user", content="Ktoś upadł w sklepie"),
        Message(role="assistant", content="Czy jest bezpiecznie?"),
    ]

    await dialogue.begin_turn("Nie rusza się", history)

    prompt = llm.calls[0][0].content
    assert "Ktoś upadł w sklepie" in prompt
    assert "Nie rusza się" in prompt
    assert "Czy jest bezpiecznie?" not in prompt


async def test_no_matching_scenario_gives_no_instructions_and_asks_again_next_turn() -> None:
    dialogue, _ = make(["0", CHOKING])

    first = await turn(dialogue, "Boli mnie głowa")
    second = await turn(dialogue, "Tata się dławi")

    assert "nie wybrano jeszcze procedury" in first
    assert "Zadławienie osoby dorosłej" in first  # the model is told what it knows
    assert "Zapytaj poszkodowanego, czy się dławi" in second


async def test_instructions_inside_a_step_come_one_per_turn_without_calling_the_model() -> None:
    # call_emergency has three instructions. Safety and response check are one each.
    dialogue, llm = make([BLS, "1", "1"])
    await turn(dialogue, "Nie rusza się")  # safety
    await turn(dialogue, "Jest bezpiecznie")  # check_response
    first = await turn(dialogue, "Nie reaguje")  # call_emergency, instruction 1
    calls_so_far = len(llm.calls)

    second = await turn(dialogue)
    third = await turn(dialogue)

    assert "poproś, żeby zadzwonił pod sto dwanaście" in first
    assert "tryb głośnomówiący" in second
    assert "zostań z poszkodowanym" in third
    assert len(llm.calls) == calls_so_far


async def test_the_question_of_a_step_comes_after_its_instructions() -> None:
    dialogue, _ = make([BLS, "1", "1", "1"])
    for text in ["Nie rusza się", "Bezpiecznie", "Nie reaguje"]:
        await turn(dialogue, text)
    for _ in range(2):  # the other two instructions of call_emergency
        await turn(dialogue)
    await turn(dialogue, "Dzwonię")  # check_breathing, instruction 1

    await turn(dialogue)
    await turn(dialogue)
    asking = await turn(dialogue)

    assert "Czy poszkodowany oddycha prawidłowo?" in asking


async def test_the_cursor_waits_when_the_answer_matches_no_condition() -> None:
    dialogue, _ = make([BLS, "0", "1"])
    await turn(dialogue, "Nie rusza się")  # safety, its only instruction

    waiting = await turn(dialogue, "Nie wiem, rozglądam się")
    moved_on = await turn(dialogue, "Jest bezpiecznie")

    assert "jeszcze nie spełnił warunku" in waiting
    assert "Upewnij się, że Ty, poszkodowany i świadkowie" in waiting  # repeats the last unit
    assert "potrząśnij" in moved_on


async def test_an_unusable_reply_of_the_router_keeps_the_cursor() -> None:
    # A digit buried in words is not trusted: a wrong step is worse than waiting.
    for reply in ["nie wiem", "", "9", "Odpowiedź: 1", "Pasują 1 i 2"]:
        dialogue, _ = make([BLS, reply])
        await turn(dialogue, "Nie rusza się")

        task = await turn(dialogue, "Jest bezpiecznie")

        assert "jeszcze nie spełnił warunku" in task, reply


async def test_a_digit_with_punctuation_around_it_is_understood() -> None:
    for reply in ["1", " 1.", "(1)", "1 - jest bezpiecznie"]:
        dialogue, _ = make([BLS, reply])
        await turn(dialogue, "Nie rusza się")

        task = await turn(dialogue, "Jest bezpiecznie")

        assert "potrząśnij" in task, reply


async def test_an_interrupted_answer_is_said_again() -> None:
    dialogue, _ = make([BLS])
    first = await dialogue.begin_turn("Nie rusza się", [])  # never completed: cancelled

    again = await turn(dialogue, "Halo?")

    assert first == again


async def test_the_step_router_sees_what_the_assistant_asked_and_what_the_user_said() -> None:
    dialogue, llm = make([BLS, "1"])
    await turn(dialogue, "Nie rusza się")
    history = [Message(role="assistant", content="Czy jest bezpiecznie?")]

    await dialogue.begin_turn("Tak, nic nie jedzie", history)

    prompt = llm.calls[-1][0].content
    assert "Czy jest bezpiecznie?" in prompt
    assert "Tak, nic nie jedzie" in prompt
    assert "1. jest bezpiecznie" in prompt


async def test_choking_that_ends_in_unconsciousness_continues_as_cpr() -> None:
    # recognise -> encourage_cough -> back_blows -> abdominal_thrusts -> call_and_alternate
    # (three instructions) -> unresponsive -> hand-off to adult-bls/chest_compressions
    dialogue, _ = make([CHOKING, "1", "3", "2", "2", "2", "1"])
    await turn(dialogue, "Dławi się")  # recognise
    await turn(dialogue, "Tak")  # encourage_cough
    await turn(dialogue, "Nie kaszle")  # back_blows
    await turn(dialogue, "Nie pomogło")  # abdominal_thrusts
    await turn(dialogue, "Nie pomogło")  # call_and_alternate
    await turn(dialogue)
    await turn(dialogue)
    await turn(dialogue, "Stracił przytomność")  # unresponsive

    task = await turn(dialogue, "Dobrze")

    assert "Uklęknij obok poszkodowanego" in task


async def test_a_finished_scenario_gives_no_new_steps() -> None:
    dialogue, llm = make([CHOKING, "1", "2"])
    await turn(dialogue, "Dławi się")  # recognise
    await turn(dialogue, "Tak")  # encourage_cough
    await turn(dialogue, "Wypluł")  # relieved, its only instruction
    calls = len(llm.calls)

    task = await turn(dialogue, "Dziękuję")

    assert "procedura jest zakończona" in task
    assert len(llm.calls) == calls


def test_websocket_gives_the_model_one_instruction_per_question() -> None:
    llm = ScriptedLLM([BLS, "Upewnij się, że nic wam nie zagraża.", "1", "Potrząśnij go."])
    app = create_app("configs/fake.yaml")
    app.state.llm = llm
    client = TestClient(app)

    with client.websocket_connect("/v1/chat") as ws:
        _ask(ws, "a1", "Kolega leży i się nie rusza", [])
        _ask(
            ws,
            "a2",
            "Jest bezpiecznie",
            [
                {"role": "user", "content": "Kolega leży i się nie rusza"},
                {"role": "assistant", "content": "Upewnij się, że nic wam nie zagraża."},
            ],
        )

    answering = [c for c in llm.calls if c[0].role == "system"]
    first, second = answering[0][0].content, answering[1][0].content
    assert "Ty, poszkodowany i świadkowie" in first
    assert "potrząśnij" not in first
    assert "potrząśnij" in second
    assert "Ty, poszkodowany i świadkowie" not in second


def _ask(ws: Any, ask_id: str, text: str, history: list[dict[str, str]]) -> None:
    ws.send_json({"type": "ask", "id": ask_id, "text": text, "history": history})
    while True:
        event = ws.receive_json()
        if event["type"] == "done" and event["id"] == ask_id:
            return
