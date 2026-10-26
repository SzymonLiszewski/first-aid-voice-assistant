from collections.abc import AsyncIterator

from app.providers.base import LLMDelta, LLMDone, LLMEvent, LLMOptions, Message
from app.providers.registry import register_llm


@register_llm("fake")
class FakeLLM:
    """Deterministic provider for tests and for running the app without a model.

    Without `reply` it echoes the last user message and the message count, which makes
    history handling observable in tests.
    """

    name = "fake"

    def __init__(self, reply: str | None = None) -> None:
        self.reply = reply

    async def generate_stream(
        self, messages: list[Message], opts: LLMOptions
    ) -> AsyncIterator[LLMEvent]:
        last_user = next((m.content for m in reversed(messages) if m.role == "user"), "")
        answer = self.reply or f"Echo ({len(messages)} messages): {last_user}"
        words = answer.split(" ")
        for i, word in enumerate(words):
            yield LLMDelta(text=word if i == 0 else f" {word}")
        yield LLMDone(text=answer)
