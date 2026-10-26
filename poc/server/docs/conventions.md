# PoC server – coding conventions

| | |
|---|---|
| **Created** | 2026-10-26 |
| **Version** | 0.1 |

## Tooling

| Tool | Use | Command |
|---|---|---|
| uv | dependencies and virtual environment (`pyproject.toml`, `uv.lock`) | `uv sync`, `uv add <pkg>` |
| ruff | formatting and linting (line length 100; rules E, F, I, UP, B, ASYNC) | `uv run ruff format`, `uv run ruff check --fix` |
| mypy | static typing in strict mode, with the pydantic plugin | `uv run mypy app` |
| pytest | tests (`asyncio_mode = auto`) | `uv run pytest` |

ruff, mypy and pytest must pass before a pull request is merged.

## Python style

- Python 3.12+. Use modern syntax: `list[str]`, `X | None`, `collections.abc` types.
- Every function and method has full type hints (mypy strict). Avoid `Any` unless an external library forces it, and keep it local.
- Data passed between modules is a pydantic model (`BaseModel`), not a bare `dict`.
- Interfaces are `typing.Protocol` classes in `app/providers/base.py`; implementations do not inherit from them.
- I/O is async (`async def`, `httpx.AsyncClient`, async generators for streaming). Do not block the event loop.
- Names: `snake_case` for functions, variables and modules; `PascalCase` for classes; `UPPER_CASE` for module constants; a leading `_` for module-private names.
- Docstrings and comments explain *why*, not *what*. A module docstring is welcome when the module's role is not obvious.
- Everything is in English (identifiers, comments, logs, error messages); only prompts in `prompts/` and `configs/domain_terms.txt` are in Polish.

## Architecture rules

- API and pipeline code never import concrete providers; they go through `app/providers/registry.py`. A new model is a registry entry plus a config, not an `if` in the pipeline.
- Configuration comes from `configs/*.yaml` (models) and `.env` (secrets, environment). No hard-coded URLs, model names or keys.
- Prompts live in `prompts/` as versioned files (`system_v1.md`, `system_v2.md`, …); do not edit a prompt that an evaluation result refers to – add a new version.
- Endpoints that are only for development go to `app/api/dev.py` and are mounted only when `DEV_MODE=true`.

## Errors and logging

- Use `logging.getLogger(__name__)`; no `print` in application code (command-line tools in `app/tools/` and `scripts/` may print).
- Log the exception with `logger.exception(...)` at the boundary, then return a clear HTTP error (e.g. 502 when the model fails). Never return a made-up answer instead of an error – the client must be able to show its "call 112" fallback.
- Do not log secrets or full user transcripts outside development.

## Tests

- `tests/unit/` – fast tests without external services; use the `fake` provider or a test config.
- `tests/contract/` – the same tests run against every provider (`PROVIDERS` list); every new provider must pass them.
- Test names describe behaviour: `test_<what>_<expected result>`.
- A bug fix comes with a test that fails without the fix.

## Revision history

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-10-26 | First version, based on the existing code and `pyproject.toml` |
