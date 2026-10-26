---
name: add-llm-provider
description: Use when adding or swapping an LLM (open model or commercial API) in the voice assistant backend.
---
> TEMPLATE – to be finished. Review and extend once the first real provider comparison has been done.

1. Check whether LiteLLM supports the model (`provider/model`). If so, only a config is needed, no new code.
2. If not, create `app/providers/llm/<name>.py` implementing `LLMProvider` (`app/providers/base.py`) and register it with `@register_llm("<name>")`; import it in `app/providers/llm/__init__.py`.
3. Add `configs/experiments/<name>.yaml` and any API keys to `.env.example`.
4. Add the provider to `PROVIDERS` in `tests/contract/test_llm_contract.py` (if it can run offline) and run `uv run pytest tests/contract`.
5. Run the `run-eval` skill and add the result to `eval/results/` at the repository root. (TODO: `eval/run_eval.py` does not exist yet.)
6. Check the first-aid safety behaviour of the new model by hand (see "Domain and safety" in the root `AGENTS.md`): it must tell the user to call 112 first and must not invent procedures.
