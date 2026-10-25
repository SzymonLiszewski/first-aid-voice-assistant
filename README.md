# Voice assistant – backend

Backend of a **voice assistant for emergencies and first aid**: a bystander talks to it, it guides them step by step (ASR → LLM, with room for RAG). Every model (open-source, self-hosted or a commercial API) can be swapped by changing the config.

> **Disclaimer.** This is a research prototype, not a medical device. Its answers are not medically validated and it does not replace emergency services. In a real emergency call **112** (ambulance: **999**).

## Architecture in brief

- Modular monolith (FastAPI) – one `app` container.
- Open-source models in separate containers (Ollama/vLLM, faster-whisper server), enabled via compose profiles.
- Commercial models behind the same provider interfaces (LiteLLM adapter).
- API: `GET /health`, `GET /v1/providers`, and the dev-only `POST /dev/chat` for testing the LLM with ready-made transcripts.
- No audio/ASR yet, and no conversation history: each request is a single, independent turn.
- RAG is disabled (`rag.enabled: false`); Qdrant sits behind the `rag` profile.

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

Without a model (echo mode, handy for UI work):

```powershell
$env:APP_CONFIG = "configs/fake.yaml"; uv run uvicorn app.main:app --reload
```

Running the app locally against the Ollama container: `$env:APP_CONFIG = "configs/local.yaml"`.

GPU: `docker compose -f docker-compose.yml -f docker-compose.gpu.yml up`.

Changing the model: edit `model` in `configs/base.yaml` and run `docker compose up` again; the `llm-pull` container downloads whatever the config names (for Ollama models). Another config can be selected with `APP_CONFIG` in `.env`.

Checks: `curl localhost:8000/health`, `curl localhost:8000/v1/providers`. Tests: `uv run pytest`.

## Configuration

Model setup lives in `configs/base.yaml` (pick another file with `APP_CONFIG`); secrets live in `.env`. Experiments go in `configs/experiments/`. The system prompt is `prompts/system_v1.md`.

## Mobile app

The mobile client (Flutter) will live in `mobile/`, next to the backend. It is not started yet. To reach the backend from an Android emulator use `http://10.0.2.2:8000`; from a physical phone use the computer's LAN address.

Working rules for code and agents: `AGENTS.md`.
