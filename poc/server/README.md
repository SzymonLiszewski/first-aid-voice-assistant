# PoC server

Test server of the first-aid voice assistant: it receives a transcript of what the user said and returns the model's answer (ASR → LLM, with room for RAG). Every model (open-source, self-hosted or a commercial API) can be swapped by changing the config.

> **Disclaimer.** This is a research prototype, not a medical device. Its answers are not medically validated and it does not replace emergency services. In a real emergency call **112**.

All commands below are run from `poc/server/`.

## Architecture in brief

- Modular monolith (FastAPI) – one `app` container.
- Open-source models in separate containers (Ollama/vLLM, faster-whisper server), enabled via compose profiles.
- Commercial models behind the same provider interfaces (LiteLLM adapter).
- API: `GET /health`, `GET /v1/providers`, `WS /v1/chat` (the mobile app's chat: the answer is streamed and can be cancelled; the app sends the conversation history with every question) and the dev-only `POST /dev/chat` for testing the LLM with ready-made transcripts.
- No audio/ASR on the server: speech is recognised on the phone.
- RAG is disabled (`rag.enabled: false`); Qdrant sits behind the `rag` profile.

More: [docs/architecture.md](docs/architecture.md). Coding conventions: [docs/conventions.md](docs/conventions.md).

## Structure

```
poc/server/
├── app/                      # backend (FastAPI)
│   ├── main.py               # app factory, wiring
│   ├── api/                  # REST endpoints, chat WebSocket (ws.py), dev-only test endpoint and page (static/)
│   ├── core/                 # config loading (env + YAML)
│   ├── pipeline/             # prompt building
│   ├── providers/            # model adapters
│   │   ├── base.py           # provider interfaces
│   │   ├── registry.py       # provider name from config -> class
│   │   ├── llm/              # LiteLLM adapter, fake LLM for tests
│   │   └── asr/ tts/ embeddings/   # empty for now
│   ├── rag/                  # empty for now
│   └── tools/                # helper commands (e.g. pulling the Ollama model)
├── configs/                  # base.yaml, fake.yaml, gemma.yaml, bielik.yaml, experiments/, domain_terms.txt
├── prompts/                  # system prompts (versioned files)
├── scripts/                  # chat_client.py (terminal test client)
├── tests/                    # unit/ and contract/ (same tests for every provider)
├── docs/                     # architecture and coding conventions of the server
├── .claude/skills/           # agent skill templates (to be finished)
├── docker-compose.yml        # app, redis, Ollama (+ model pull); profiles: local-asr, rag
├── docker-compose.gpu.yml    # GPU override
├── Dockerfile
├── pyproject.toml, uv.lock   # dependencies (uv)
├── .env.example              # settings and API keys template
└── AGENTS.md, CLAUDE.md      # rules for working on the server
```

The knowledge base (`knowledge/`) and the evaluation (`eval/`) live at the repository root, because they are shared with the mobile app and the target application.

## Requirements

- Python 3.12+, [uv](https://docs.astral.sh/uv/)
- Docker + Docker Compose (GPU: NVIDIA Container Toolkit)

## Running

```bash
docker compose up --build
```

That is all: it starts the app, Redis and Ollama, and downloads the default model (`gemma3:1b`, ~0.8 GB) on the first run. The app starts once the model is ready, so the first start takes a few minutes. `.env` is optional (`cp .env.example .env` to change settings).

Then open **http://localhost:8000/dev**, paste a transcript and send it. Or use the terminal client:

```bash
uv run python scripts/chat_client.py "Mój kolega nie oddycha, co mam robić?"
```

Without a model (a fixed Polish answer streamed slowly, handy for UI work):

```powershell
$env:APP_CONFIG = "configs/fake.yaml"; uv run uvicorn app.main:app --reload
```

Running the app locally against the Ollama container: `$env:APP_CONFIG = "configs/gemma.yaml"` (Gemma 3 1B) or `"configs/bielik.yaml"` (Bielik 4.5B v3; pull it once with `docker compose exec llm ollama pull hf.co/speakleash/Bielik-4.5B-v3.0-Instruct-GGUF:Q8_0`).

GPU: `docker compose -f docker-compose.yml -f docker-compose.gpu.yml up`.

Changing the model: edit `model` in `configs/base.yaml` and run `docker compose up` again; the `llm-pull` container downloads whatever the config names (for Ollama models). Another config can be selected with `APP_CONFIG` in `.env`.

## Checks

```bash
uv sync
uv run pytest
uv run ruff check . && uv run ruff format --check .
uv run mypy app
```

Health: `curl localhost:8000/health`, `curl localhost:8000/v1/providers`.

## Configuration

Model setup lives in `configs/base.yaml` (pick another file with `APP_CONFIG`); secrets live in `.env`. Experiments go in `configs/experiments/`. The system prompt is `prompts/system_v1.md`.

## Mobile client

The demo mobile app lives in [`../mobile`](../mobile); it connects to `ws://<address>/v1/chat` (the address is set in the app's settings). From an Android emulator use `http://10.0.2.2:8000`; from a physical phone use the computer's LAN address and start the server with `--host 0.0.0.0` (`docker compose` already publishes the port).

To try reading aloud and interrupting without a model:

```powershell
$env:APP_CONFIG = "configs/fake.yaml"; uv run uvicorn app.main:app --host 0.0.0.0
```

Working rules for code and agents: [AGENTS.md](AGENTS.md) (and the project-wide [AGENTS.md](../../AGENTS.md)).
