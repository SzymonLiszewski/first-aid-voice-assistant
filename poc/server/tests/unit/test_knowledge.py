import shutil
from collections.abc import Callable
from pathlib import Path
from typing import Any

import pytest
import yaml
from fastapi.testclient import TestClient

from app.knowledge import KnowledgeError, compose_system_prompt, load_knowledge
from app.knowledge.render import render_procedures
from app.main import create_app

KNOWLEDGE = Path("../../knowledge")
PROMPT_TEMPLATE = Path("prompts/knowledge_v1.md")


@pytest.fixture
def kb_copy(tmp_path: Path) -> Path:
    """A throw-away copy of the real scenarios (no sources folder) to break in tests."""
    root = tmp_path / "knowledge"
    shutil.copytree(
        KNOWLEDGE / "scenarios", root / "scenarios", ignore=shutil.ignore_patterns("README.md")
    )
    return root


def _write_source(root: Path, source_id: str, sections: list[str]) -> None:
    (root / "sources").mkdir(exist_ok=True)
    data = {
        "id": source_id,
        "title": "t",
        "publisher": "p",
        "version": "1",
        "urls": ["https://example.org"],
        "accessed": "2026-01-01",
        "sections": sections,
    }
    (root / "sources" / f"{source_id}.yaml").write_text(yaml.safe_dump(data), encoding="utf-8")


def _edit_scenario(root: Path, name: str, change: Callable[[dict[str, Any]], None]) -> None:
    path = root / "scenarios" / f"{name}.yaml"
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    change(data)
    path.write_text(yaml.safe_dump(data, allow_unicode=True), encoding="utf-8")


def test_real_knowledge_base_is_valid() -> None:
    kb = load_knowledge(KNOWLEDGE)

    assert {s.id for s in kb.scenarios} >= {"adult-bls", "adult-choking"}
    assert {a.code for a in kb.actions} >= {"CHEST_COMPRESSIONS", "BACK_BLOWS"}


def test_bls_scenario_keeps_the_official_numbers() -> None:
    text = render_procedures(load_knowledge(KNOWLEDGE))

    # ERC 2025 / PRR: 5-6 cm, 100-120 per minute, 30:2, 10 seconds, check response before call.
    assert "co najmniej pięciu, ale nie więcej niż sześciu centymetrów" in text
    assert "od stu do stu dwudziestu uciśnięć na minutę" in text
    assert "trzydzieści uciśnięć do dwóch oddechów" in text
    assert "nie dłużej niż dziesięć sekund" in text


def test_bls_calls_for_help_before_checking_breathing() -> None:
    bls = next(s for s in load_knowledge(KNOWLEDGE).scenarios if s.id == "adult-bls")
    order = [bls.start]
    while bls.step(order[-1]).transitions and len(order) < 10:
        order.append(bls.step(order[-1]).transitions[0].goto or "")
        if order[-1] in order[:-1]:
            break

    assert order.index("call_emergency") < order.index("check_breathing")


def test_choking_escalates_from_cough_to_back_blows_to_abdominal_thrusts() -> None:
    choking = next(s for s in load_knowledge(KNOWLEDGE).scenarios if s.id == "adult-choking")

    def targets(step_id: str) -> set[str | None]:
        return {t.goto for t in choking.step(step_id).transitions}

    assert "back_blows" in targets("encourage_cough")
    assert "abdominal_thrusts" in targets("back_blows")
    assert "call_and_alternate" in targets("abdominal_thrusts")


def test_citations_are_not_checked_without_source_files(kb_copy: Path) -> None:
    _edit_scenario(
        kb_copy, "adult-bls", lambda d: d["steps"][0]["sources"][0].update(source="made-up")
    )

    assert load_knowledge(kb_copy).sources == []


def test_unknown_step_in_transition_is_rejected(kb_copy: Path) -> None:
    _edit_scenario(
        kb_copy, "adult-bls", lambda d: d["steps"][0]["transitions"][0].update(goto="nowhere")
    )

    with pytest.raises(KnowledgeError, match="unknown step 'nowhere'"):
        load_knowledge(kb_copy)


def test_unknown_action_is_rejected(kb_copy: Path) -> None:
    _edit_scenario(kb_copy, "adult-bls", lambda d: d["steps"][1].update(actions=["NOT_AN_ACTION"]))

    with pytest.raises(KnowledgeError, match="unknown action 'NOT_AN_ACTION'"):
        load_knowledge(kb_copy)


def test_unknown_source_is_rejected(kb_copy: Path) -> None:
    _write_source(kb_copy, "erc-2025-bls", ["Safety"])
    _edit_scenario(
        kb_copy, "adult-bls", lambda d: d["steps"][0]["sources"][0].update(source="made-up")
    )

    with pytest.raises(KnowledgeError, match="unknown source 'made-up'"):
        load_knowledge(kb_copy)


def test_section_missing_from_the_source_is_rejected(kb_copy: Path) -> None:
    _write_source(kb_copy, "erc-2025-bls", ["Safety"])
    _edit_scenario(
        kb_copy, "adult-bls", lambda d: d["steps"][0]["sources"][1].update(section="Invented")
    )

    with pytest.raises(KnowledgeError, match="section 'Invented' is not listed"):
        load_knowledge(kb_copy)


def test_unreachable_step_is_rejected(kb_copy: Path) -> None:
    _edit_scenario(
        kb_copy,
        "adult-choking",
        lambda d: d["steps"].append(
            {
                "id": "orphan",
                "instructions": ["x"],
                "sources": [{"source": "erc-2025-first-aid", "section": "Choking in an adult"}],
            }
        ),
    )

    with pytest.raises(KnowledgeError, match="'orphan' is unreachable"):
        load_knowledge(kb_copy)


def test_handoff_to_unknown_scenario_is_rejected(kb_copy: Path) -> None:
    def change(d: dict[str, Any]) -> None:
        step = next(s for s in d["steps"] if s["id"] == "unresponsive")
        step["transitions"][0]["handoff"] = "adult-bls/missing"

    _edit_scenario(kb_copy, "adult-choking", change)

    with pytest.raises(KnowledgeError, match="hand-off to unknown 'adult-bls/missing'"):
        load_knowledge(kb_copy)


def test_system_prompt_contains_base_prompt_and_procedures() -> None:
    base = Path("prompts/system_v1.md").read_text(encoding="utf-8")

    prompt = compose_system_prompt(base, PROMPT_TEMPLATE, load_knowledge(KNOWLEDGE))

    assert prompt.startswith(base.rstrip())
    assert "SCENARIO adult-bls" in prompt
    assert "{procedures}" not in prompt


def test_template_without_placeholder_is_rejected(tmp_path: Path) -> None:
    template = tmp_path / "t.md"
    template.write_text("no placeholder", encoding="utf-8")

    with pytest.raises(ValueError, match="must contain"):
        compose_system_prompt("base", template, load_knowledge(KNOWLEDGE))


def test_model_receives_the_procedures_in_a_single_system_message() -> None:
    client = TestClient(create_app("configs/fake.yaml"))

    prompt = client.app.state.system_prompt  # type: ignore[attr-defined]

    assert "SCENARIO adult-choking" in prompt
    assert "Zasady bezpieczeństwa" in prompt  # the safety rules are still there
