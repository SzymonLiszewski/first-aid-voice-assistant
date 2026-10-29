"""Renders the scenarios as plain text for the system prompt.

The keywords (STEP, SAY, ASK, IF, GOTO, HANDOFF, END) are explained to the model in the
prompt template (`prompts/knowledge_v1.md`), which also carries all wording addressed to it.
"""

from pathlib import Path

from app.knowledge.models import KnowledgeBase, Scenario, Step

PLACEHOLDER = "{procedures}"


def render_procedures(kb: KnowledgeBase) -> str:
    return "\n\n".join(_scenario(sc) for sc in kb.scenarios)


def compose_system_prompt(base_prompt: str, template_path: str | Path, kb: KnowledgeBase) -> str:
    template = Path(template_path).read_text(encoding="utf-8")
    if PLACEHOLDER not in template:
        raise ValueError(f"{template_path} must contain {PLACEHOLDER}")
    knowledge = template.replace(PLACEHOLDER, render_procedures(kb))
    return f"{base_prompt.rstrip()}\n\n{knowledge.strip()}\n"


def _scenario(sc: Scenario) -> str:
    lines = [
        f"## SCENARIO {sc.id}: {sc.title}",
        f"USE WHEN: {sc.trigger.strip()}",
        f"START: {sc.start}",
    ]
    lines.extend(_step(s) for s in sc.steps)
    return "\n".join(lines)


def _step(step: Step) -> str:
    lines = [f"STEP {step.id}"]
    lines.extend(f"  SAY {i}: {text}" for i, text in enumerate(step.instructions, 1))
    if step.asks:
        lines.append(f"  ASK: {step.asks}")
    for tr in step.transitions:
        target = f"GOTO {tr.goto}" if tr.goto else f"HANDOFF {tr.handoff}"
        lines.append(f"  IF {' '.join(tr.when.split())} -> {target}")
    if not step.transitions:
        lines.append("  END")
    return "\n".join(lines)
