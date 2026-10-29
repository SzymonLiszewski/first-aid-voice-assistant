# PoC server – architecture

| | |
|---|---|
| **Created** | 2026-10-26 |
| **Version** | 0.2 |

## Purpose

The PoC server is the part of the demo that talks to the language model. The mobile app sends it what the user said (a transcript) and gets back the assistant's answer. The server hides which model is used: open-source models in local containers and commercial APIs are interchangeable through configuration.

## Components

```
            ┌───────────────────────── app container (FastAPI) ─────────────────────────┐
request ──▶ │ api/  ──▶ pipeline/prompt.py ──▶ providers/registry ──▶ providers/llm/<name> │ ──▶ model
            │   ▲                                                                       │
            │   └── core/config.py (YAML config + .env settings), prompts/*.md          │
            └───────────────────────────────────────────────────────────────────────────┘
```

| Module | Responsibility |
|---|---|
| `app/main.py` | App factory (`create_app`): loads settings and the YAML config, builds the LLM provider, reads the system prompt, mounts the routers. |
| `app/core/config.py` | `Settings` (environment variables / `.env`) and `AppConfig` (YAML: ASR, LLM, RAG, prompts). |
| `app/api/rest.py` | Public endpoints: `GET /health`, `GET /v1/providers`. |
| `app/api/ws.py` | `WS /v1/chat`: the mobile app's chat – streams the answer, cancels it on request (see below). |
| `app/api/dev.py` | Dev-only `GET /dev` (test page) and `POST /dev/chat`, mounted only when `DEV_MODE=true`. |
| `app/pipeline/prompt.py` | Builds the message list: system prompt + history + user text. |
| `app/providers/base.py` | Provider interfaces and data types (`Message`, `LLMOptions`, `LLMDelta`, `LLMDone`, `LLMProvider`). |
| `app/providers/registry.py` | Maps the provider name from the config to a class (`@register_llm("<name>")`, `build_llm`). |
| `app/providers/llm/` | LLM adapters: `litellm` (Ollama, vLLM, commercial APIs) and `fake` (tests, no model; `delay` imitates a slow model). |
| `app/tools/pull_model.py` | One-shot command that pulls the configured Ollama model (`llm-pull` container). |

`app/providers/asr`, `tts`, `embeddings` and `app/rag` are placeholders for the next stages.

## Chat over a WebSocket (`WS /v1/chat`)

Used by the mobile app. Messages are JSON objects with a `type`.

| Direction | `type` | Fields | Meaning |
|---|---|---|---|
| app → server | `ask` | `id`, `text` (1–2000 chars), `history` (`[{role: user/assistant, content}]`, up to 50) | New question; cancels the answer in progress |
| app → server | `cancel` | `id` | Stop that answer (e.g. the user interrupted it) |
| server → app | `delta` | `id`, `text` | Next piece of the answer |
| server → app | `done` | `id`, `text`, `first_token_ms`, `total_ms` | Full answer and timings |
| server → app | `cancelled` | `id` | The answer was stopped |
| server → app | `error` | `id` (or `null` for an invalid message), `message` | The model failed or the message was invalid; the connection stays open |

1. `api/ws.py` reads messages in a loop; each `ask` starts a task that streams the answer, so the loop keeps reading and can cancel it.
2. `pipeline/prompt.py` builds `[system prompt, *history, question]`. The history comes from the app with every question – the server keeps no conversation state.
3. Every `LLMDelta` is sent as `delta`; the final `LLMDone` as `done`. A model failure becomes `error`, so the app can say "call 112".
4. A new `ask`, a `cancel` or a closed connection cancels the streaming task, which stops the model call.

## Request flow (`POST /dev/chat`)

1. `api/dev.py` validates the body (`{"text": "..."}`, 1–2000 characters).
2. `pipeline/prompt.py` builds `[system prompt, user text]` (no history – every request is a single turn).
3. The configured provider streams `LLMDelta` events and ends with exactly one `LLMDone` carrying the full answer.
4. The endpoint returns `{"answer", "elapsed_ms"}`. If the model fails, it returns HTTP 502 so the client can show its "call 112" fallback.

## Configuration

- `configs/*.yaml` select the providers and their parameters (`APP_CONFIG` picks the file): `base.yaml` (Docker), `gemma.yaml` (app on the host, Gemma 3 1B in the Ollama container), `bielik.yaml` (app on the host, Bielik 4.5B v3 in the Ollama container), `fake.yaml` (no model, streams a fixed Polish answer word by word with a delay – for UI work and trying the app; tests swap in an echoing fake).
- `.env` holds secrets and environment settings (`DEV_MODE`, API keys, `REDIS_URL`).
- Experiments with other models go to `configs/experiments/`.

## Runtime (docker compose)

| Service | Role | Profile |
|---|---|---|
| `app` | FastAPI server | default |
| `redis` | Session store (not used yet) | default |
| `llm` | Ollama model server | default |
| `llm-pull` | Pulls the configured model once, then exits | default |
| `asr` | faster-whisper server with an OpenAI-compatible API | `local-asr` |
| `qdrant` | Vector database for RAG | `rag` |

`docker-compose.gpu.yml` adds GPU access to `llm` and `asr`.

## Not implemented yet

- ASR / audio input (in the demo, speech recognition is planned on the phone).
- Sessions on the server, the event log.
- Authentication of the WebSocket (PoC in a local network only).
- The analysis endpoint for the mobile app (recognised actions and the next step).
- RAG over the knowledge base.

## Revision history

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-10-26 | First version, based on the existing code |
| 0.2 | 2026-10-29 | `WS /v1/chat` with streamed answers, cancelling and history sent by the app; `gemma.yaml`, `bielik.yaml`; `fake.yaml` streams a fixed answer slowly |
