from collections.abc import AsyncIterator
from typing import Literal, Protocol

from pydantic import BaseModel


class Message(BaseModel):
    role: Literal["system", "user", "assistant"]
    content: str


class LLMOptions(BaseModel):
    max_tokens: int | None = None
    temperature: float | None = None


class LLMDelta(BaseModel):
    """A chunk of the answer as it is generated."""

    text: str


class LLMDone(BaseModel):
    """Emitted exactly once, last; carries the full answer."""

    text: str


LLMEvent = LLMDelta | LLMDone


class LLMProvider(Protocol):
    name: str

    def generate_stream(
        self, messages: list[Message], opts: LLMOptions
    ) -> AsyncIterator[LLMEvent]: ...
