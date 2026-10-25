from collections.abc import AsyncIterator
from typing import Any

import litellm

from app.providers.base import LLMDelta, LLMDone, LLMEvent, LLMOptions, Message
from app.providers.registry import register_llm


@register_llm("litellm")
class LiteLLMProvider:
    """One adapter for Ollama, vLLM and commercial APIs; the model is picked by `model`.

    LiteLLM is a library that exposes many LLM vendors behind one OpenAI-style interface.
    The `model` string is "<vendor>/<model name>" (e.g. "ollama_chat/qwen3:4b"), and LiteLLM
    translates the call and the streamed response for that vendor. Switching models is
    therefore a config change, not new code.
    """

    name = "litellm"

    def __init__(
        self,
        model: str,
        api_base: str | None = None,
        temperature: float = 0.3,
        timeout: float = 60.0,
        **extra: Any,
    ) -> None:
        self.model = model
        self.api_base = api_base
        self.temperature = temperature
        self.timeout = timeout
        self.extra = extra

    async def generate_stream(
        self, messages: list[Message], opts: LLMOptions
    ) -> AsyncIterator[LLMEvent]:
        # Async generator: each `yield` hands one event to the caller (`async for`) right away,
        # so text can be passed on while the model is still generating.
        response: Any = await litellm.acompletion(
            model=self.model,
            messages=[m.model_dump() for m in messages],
            api_base=self.api_base,
            temperature=opts.temperature if opts.temperature is not None else self.temperature,
            max_tokens=opts.max_tokens,
            timeout=self.timeout,
            stream=True,
            **self.extra,
        )
        parts: list[str] = []
        async for chunk in response:
            text = chunk.choices[0].delta.content
            if text:
                parts.append(text)
                yield LLMDelta(text=text)
        yield LLMDone(text="".join(parts))
