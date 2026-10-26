import json

import httpx
import pytest

from app.core.config import ProviderConfig
from app.tools.pull_model import ollama_model_name, pull


@pytest.mark.parametrize(
    ("provider", "model", "expected"),
    [
        ("litellm", "ollama_chat/qwen3:4b", "qwen3:4b"),
        ("litellm", "ollama/llama3.2:3b", "llama3.2:3b"),
        ("litellm", "anthropic/claude-sonnet-5-5", None),
        ("fake", "ollama/qwen3:4b", None),
    ],
)
def test_ollama_model_name(provider: str, model: str, expected: str | None) -> None:
    cfg = ProviderConfig(provider=provider, params={"model": model})
    assert ollama_model_name(cfg) == expected


def _client(lines: list[dict[str, str]]) -> httpx.Client:
    body = "\n".join(json.dumps(line) for line in lines)

    def handler(request: httpx.Request) -> httpx.Response:
        assert json.loads(request.content) == {"model": "qwen3:4b"}
        return httpx.Response(200, text=body)

    return httpx.Client(base_url="http://llm:11434", transport=httpx.MockTransport(handler))


def test_pull_prints_progress(capsys: pytest.CaptureFixture[str]) -> None:
    pull(_client([{"status": "pulling manifest"}, {"status": "success"}]), "qwen3:4b")
    assert capsys.readouterr().out.split() == ["pulling", "manifest", "success"]


def test_pull_raises_on_error() -> None:
    with pytest.raises(RuntimeError, match="model not found"):
        pull(_client([{"error": "model not found"}]), "qwen3:4b")
