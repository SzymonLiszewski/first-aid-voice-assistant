from typing import Any

import pytest
from fastapi.testclient import TestClient

from app.main import create_app


@pytest.fixture
def client(monkeypatch: pytest.MonkeyPatch) -> TestClient:
    monkeypatch.setenv("DEV_MODE", "true")
    return TestClient(create_app("configs/fake.yaml"))


def test_chat_returns_answer(client: TestClient) -> None:
    r = client.post("/dev/chat", json={"text": "Mój kolega nie oddycha"})
    assert r.status_code == 200
    body = r.json()
    assert "Mój kolega nie oddycha" in body["answer"]
    assert body["elapsed_ms"] >= 0


def test_chat_sends_system_prompt_and_user_text(client: TestClient) -> None:
    # FakeLLM reports the message count: system prompt + user text = 2.
    assert "2 messages" in client.post("/dev/chat", json={"text": "hej"}).json()["answer"]


def test_chat_rejects_empty_text(client: TestClient) -> None:
    assert client.post("/dev/chat", json={"text": ""}).status_code == 422


def test_chat_model_failure_is_502(client: TestClient) -> None:
    class Boom:
        name = "boom"

        def generate_stream(self, *args: Any, **kwargs: Any) -> Any:
            raise RuntimeError("model down")

    client.app.state.llm = Boom()  # type: ignore[attr-defined]
    assert client.post("/dev/chat", json={"text": "hej"}).status_code == 502


def test_dev_endpoints_hidden_without_dev_mode(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("DEV_MODE", "false")
    c = TestClient(create_app("configs/fake.yaml"))
    assert c.get("/dev").status_code == 404
    assert c.post("/dev/chat", json={"text": "hej"}).status_code == 404
