from pathlib import Path

from fastapi import FastAPI

from app.api import dev, rest, ws
from app.core.config import AppConfig, Settings, load_config
from app.knowledge import compose_system_prompt, load_knowledge
from app.providers.registry import build_llm


def _build_system_prompt(config: AppConfig) -> str:
    prompt = Path(config.prompts.system).read_text(encoding="utf-8")
    if not config.knowledge.enabled:
        return prompt
    if config.prompts.knowledge is None:
        raise ValueError("knowledge.enabled needs prompts.knowledge (the prompt template)")
    # A broken knowledge base raises here, so the server does not start with wrong procedures.
    return compose_system_prompt(
        prompt, config.prompts.knowledge, load_knowledge(config.knowledge.path)
    )


def create_app(config_path: str | None = None) -> FastAPI:
    settings = Settings()
    config = load_config(config_path or settings.app_config)

    app = FastAPI(title="Voice Assistant")
    app.state.config = config
    app.state.llm = build_llm(config.llm)
    app.state.system_prompt = _build_system_prompt(config)

    app.include_router(rest.router)
    app.include_router(ws.router)
    if settings.dev_mode:
        app.include_router(dev.router)
    return app


app = create_app()
