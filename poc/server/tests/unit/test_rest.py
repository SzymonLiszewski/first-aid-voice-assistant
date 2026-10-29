from fastapi.testclient import TestClient

from app.main import create_app

client = TestClient(create_app("configs/base.yaml"))


def test_health() -> None:
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_providers_reflect_config() -> None:
    body = client.get("/v1/providers").json()
    assert body["asr"]["provider"] == "openai_compat"
    assert body["llm"]["provider"] == "litellm"
    assert body["rag"] == {"enabled": False}
