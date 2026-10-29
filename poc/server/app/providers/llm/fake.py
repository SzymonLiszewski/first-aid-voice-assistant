import asyncio
from collections.abc import AsyncIterator

from app.providers.base import LLMDelta, LLMDone, LLMEvent, LLMOptions, Message
from app.providers.registry import register_llm


@register_llm("fake")
class FakeLLM:
    """Deterministic provider for tests and for running the app without a model.

    Without `reply` it echoes the last user message and the message count, which makes
    history handling observable in tests. `delay` (seconds per word) imitates a model that
    streams slowly, e.g. to try out cancelling an answer.
    """

    name = "fake"

    def __init__(self, reply: str | None = None, delay: float = 0.0) -> None:
        self.reply = reply
        self.delay = delay

    async def generate_stream(
        self, messages: list[Message], opts: LLMOptions
    ) -> AsyncIterator[LLMEvent]:
        last_user = next((m.content for m in reversed(messages) if m.role == "user"), "")
        answer = self.reply or f"Echo ({len(messages)} messages): {last_user}"
        words = answer.split(" ")
        for i, word in enumerate(words):
            if self.delay:
                await asyncio.sleep(self.delay)
            yield LLMDelta(text=word if i == 0 else f" {word}")
        yield LLMDone(text=answer)
