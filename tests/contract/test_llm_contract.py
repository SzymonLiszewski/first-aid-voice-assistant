from typing import Any

import pytest

from app.core.config import ProviderConfig
from app.providers.base import LLMDelta, LLMDone, LLMOptions, Message
from app.providers.registry import build_llm

# Providers that run offline. Real providers (litellm + a model server) need a running
# backend and are added here once there is a way to run them in CI.
PROVIDERS: list[tuple[str, dict[str, Any]]] = [("fake", {})]


@pytest.mark.parametrize(("provider", "params"), PROVIDERS)
async def test_stream_ends_with_single_done_matching_deltas(
    provider: str, params: dict[str, Any]
) -> None:
    llm = build_llm(ProviderConfig(provider=provider, params=params))
    messages = [
        Message(role="system", content="Be brief."),
        Message(role="user", content="Hello"),
    ]

    events = [ev async for ev in llm.generate_stream(messages, LLMOptions())]

    *deltas, done = events
    assert isinstance(done, LLMDone)
    assert all(isinstance(d, LLMDelta) for d in deltas)
    assert "".join(d.text for d in deltas if isinstance(d, LLMDelta)) == done.text


def test_unknown_provider_raises() -> None:
    with pytest.raises(ValueError, match="Unknown LLM provider"):
        build_llm(ProviderConfig(provider="does-not-exist"))
