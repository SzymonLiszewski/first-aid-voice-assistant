# Voice assistant – agent instructions

Voice assistant backend (ASR → LLM, with RAG as a disabled, optional stage). A modular monolith (FastAPI) plus open-source models in separate containers (Ollama/vLLM, faster-whisper server) or commercial APIs behind the same provider interfaces. For now there is no audio/ASR layer: the only way to talk to the model is the dev-only test endpoint `POST /dev/chat` (transcript in, answer out).
## Domain and safety

The assistant is for **emergencies and first aid**: a stressed bystander talks to it by voice and it guides them step by step. It is a research prototype, not a medical device, and its answers are not medically validated.

- The system prompt (`prompts/system_v1.md`) carries the safety rules: tell the user to call 112 (ambulance 999 in Poland) first, safety of the rescuer first, no diagnoses, no drug dosing, never invent procedures, one short instruction at a time. Do not weaken or remove these rules; any prompt change must be re-checked against them (and, ideally, reviewed by a medical professional).
- Every client must show a "call 112" fallback when the backend is unreachable or returns an `error` event. The assistant must never be the only way to get help.
- Medical facts should eventually come from vetted sources via RAG, not from the model's memory.
- Prefer failing loudly over guessing: an honest "I don't know, call 112" beats a confident wrong answer.

Status: the LLM can be tested with ready-made transcripts (LiteLLM + fake providers, stateless single turns). Not yet: ASR/audio, conversation history, sessions, streaming transport.

## Dev client

With `DEV_MODE=true` the app serves a test page at `/dev` and `POST /dev/chat` (`{"text": "..."}` → `{"answer", "elapsed_ms"}`); `scripts/chat_client.py` is the terminal equivalent. The endpoint is stateless and has no auth, so it must stay dev-only.

## Directory map

- `app/api/` – REST + dev test endpoint/page; `app/core/` – config, logging
- `app/pipeline/` – prompt building (orchestration comes later)
- `app/providers/` – interfaces (`base.py`), registry (`registry.py`), adapters in `asr/ llm/ embeddings/ tts/`
- `app/rag/` – `Retriever` + `NullRetriever`
- `configs/` – `base.yaml`, `experiments/`; `prompts/` – system prompts
- `eval/` – evaluation datasets and results; `tests/unit`, `tests/contract`

## Commands

```
uv sync                                   # dependencies
APP_CONFIG=configs/fake.yaml uv run uvicorn app.main:app --reload   # no model needed (PowerShell: $env:APP_CONFIG=...)
uv run python scripts/chat_client.py "..."                         # terminal test client
docker compose up --build                 # app + redis + Ollama (pulls the default model once)
docker compose --profile local-asr up                              # + local ASR server
uv run pytest
uv run ruff check . && uv run ruff format --check .
uv run mypy app
```

## Skills

Templates in `.claude/skills/` (`add-llm-provider`, `add-asr-provider`, `swap-model`, `run-eval`, `add-knowledge-source`, `add-local-model-service`). Each is marked as a template to finish; complete them as the pieces they depend on appear.

## Rules

- Pipeline and API code never import concrete providers; new models go through the registry plus a config entry only.
- Every provider must pass the contract tests (`tests/contract`).
- Secrets live only in `.env` (template: `.env.example`).
- Prompts live in `prompts/`, not in code.
- Language: all code is written in English – identifiers, comments, docstrings, error and log messages, YAML configs and `docker-compose` comments. Only end-user-facing content (prompts in `prompts/`, the `configs/domain_terms.txt` glossary) may be in Polish; the assistant is mainly configured for Polish, but that does not change the language of the code. All documentation (`README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/`) is in English as well.
- A model change means a new config in `configs/experiments/` plus an entry in the evaluation results table.

## Definition of done

Tests, ruff and mypy pass; an example config is added; an evaluation results entry is added if the change concerns a model.
