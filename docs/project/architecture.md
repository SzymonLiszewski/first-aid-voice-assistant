# System architecture

| | |
|---|---|
| **Created** | 2026-10-26 |
| **Version** | 0.1 |

## Overview

```
┌──────────────────────── PHONE ────────────────────────┐        ┌──────────── SERVER ────────────┐
│ microphone → VAD → ASR (Whisper, on device)           │        │ API → prompt → LLM provider ──▶ LLM (local container
│        │                                              │ request│        ▲                       │      or cloud API)
│        └──▶ transcript + end-of-utterance time ───────┼───────▶│        └── knowledge base       │
│                                                       │        │            (rules, scenarios)  │
│ event log (local DB) ◀── recognised actions ◀─────────┼────────┤                                │
│ screen + TTS        ◀── next step                     │response└────────────────────────────────┘
└───────────────────────────────────────────────────────┘
```

| Component | Where | Role | Implementation |
|---|---|---|---|
| Audio capture + VAD | phone | Continuous listening, splitting speech into utterances | `poc/mobile` (planned) |
| ASR | phone | Speech to text, works offline | Whisper via whisper.cpp (planned) |
| API | server | Request and response formats between the phone and the server | FastAPI / Pydantic models in `poc/server`, browsable at `/docs` |
| Server | server | Builds the prompt, calls the LLM, returns recognised actions and the next step | `poc/server` (FastAPI) |
| LLM | container or cloud | Recognises actions, chooses the next step from the scenario | LiteLLM adapter: Ollama, vLLM or commercial APIs |
| Knowledge base | repository | Vetted sources turned into an action dictionary and scenarios | `knowledge/` |
| Event log | phone | Timestamped record of recognised actions, export | `poc/mobile` (planned) |
| TTS | phone | Reads prompts aloud; listening paused while speaking | system TTS (planned) |
| Evaluation | repository | WER of ASR, agreement of the event log with the reference log, latency | `eval/` |

## Key decisions

- **The action state lives on the phone.** The app sends the event history and the current scenario step with every request, so the server keeps no sessions. This also makes it easier to move the LLM onto the phone later.
- **Timestamps are taken at the end of the utterance**, not when the answer arrives, so server latency does not distort the event log.
- **Models are swappable by configuration** (provider registry on the server), so that local and cloud models can be compared on the same corpus.

## Event log entry

> Draft – to be confirmed while building the demo.

The same format is used by the mobile app (event log), the server (recognised actions) and the evaluation (reference logs in `eval/`), so it is defined here once.

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Unique identifier of the entry |
| `timestamp` | string (ISO 8601 with time zone) | End of the utterance in which the action was reported |
| `elapsed_s` | number | Seconds since the start of the action |
| `action` | string | Action code from the action dictionary in `knowledge/scenarios/` |
| `transcript` | string | Recognised text of the utterance |
| `confidence` | number (0–1) | Confidence of the recognition |
| `source` | `local` / `cloud` | Which model produced the result |

## Online and offline

| Function | Online | Offline |
|---|---|---|
| Speech recognition | cloud or on-device model | on-device model |
| Action recognition and prompts | large LLM | small local LLM (planned: e.g. a quantised Polish model on the phone) |
| Event log | yes | yes – phone clock |
| Voice prompts | yes | yes – system TTS |
| Log synchronisation | yes | after the network returns |
| Knowledge base and model updates | yes | no – last downloaded version |

In the current PoC the LLM runs on the server, so the offline mode is a later stage.

## Revision history

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-10-26 | First version, based on the system concept document and the PoC |
