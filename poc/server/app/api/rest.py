from fastapi import APIRouter, Request

router = APIRouter()


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/v1/providers")
async def providers(request: Request) -> dict[str, object]:
    cfg = request.app.state.config
    # Report configuration only; real reachability checks are not implemented yet.
    return {
        "asr": {"provider": cfg.asr.provider, "params": cfg.asr.params, "status": "not_checked"},
        "llm": {"provider": cfg.llm.provider, "params": cfg.llm.params, "status": "not_checked"},
        "rag": {"enabled": cfg.rag.enabled},
    }
