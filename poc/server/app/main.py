from pathlib import Path

from fastapi import FastAPI

from app.api import dev, rest, ws
from app.core.config import Settings, load_config
from app.providers.registry import build_llm


def create_app(config_path: str | None = None) -> FastAPI:
    settings = Settings()
    config = load_config(config_path or settings.app_config)

    app = FastAPI(title="Voice Assistant")
    app.state.config = config
    app.state.llm = build_llm(config.llm)
    app.state.system_prompt = Path(config.prompts.system).read_text(encoding="utf-8")

    app.include_router(rest.router)
    app.include_router(ws.router)
    if settings.dev_mode:
        app.include_router(dev.router)
    return app


app = create_app()
