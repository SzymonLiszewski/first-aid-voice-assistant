from collections.abc import Callable
from importlib import import_module
from typing import Any

from app.core.config import ProviderConfig
from app.providers.base import LLMProvider

LLM_PROVIDERS: dict[str, Callable[..., LLMProvider]] = {}


def register_llm(name: str) -> Callable[[Callable[..., LLMProvider]], Callable[..., LLMProvider]]:
    def deco(factory: Callable[..., LLMProvider]) -> Callable[..., LLMProvider]:
        LLM_PROVIDERS[name] = factory
        return factory

    return deco


def build_llm(cfg: ProviderConfig) -> LLMProvider:
    # Importing the package registers every adapter; done lazily to avoid import cycles.
    import_module("app.providers.llm")
    try:
        factory: Any = LLM_PROVIDERS[cfg.provider]
    except KeyError:
        known = ", ".join(sorted(LLM_PROVIDERS)) or "none"
        raise ValueError(f"Unknown LLM provider '{cfg.provider}' (registered: {known})") from None
    provider: LLMProvider = factory(**cfg.params)
    return provider
