# PoC mobile app – architecture

| | |
|---|---|
| **Created** | 2026-10-26 |
| **Version** | 0.1 |

> Status: planned. The app does not exist yet; this document describes the intended design and will be updated as the app is built.

## Flow

```
microphone ─▶ VAD (speech segments) ─▶ Whisper on the phone ─▶ transcript + end-of-utterance time
                                                                        │
                                                                        ▼
            event log (local DB) ◀── recognised actions ◀── PoC server (LLM) ◀── request
                                         │
                                         └──▶ next step ─▶ screen + TTS (listening paused while speaking)
```

## Screens

| Screen | Content |
|---|---|
| Start | "Start helping" button, layperson / paramedic mode, "call 112" button |
| Action | Current instruction in large text, listening / analysing / speaking indicator, action timer, 2-minute cycle counter, latest events, "Finish" button |
| Summary | Timeline of recorded actions with absolute and relative times, export of the event log to JSON |
| Debug (hidden) | Transcript, raw model response (JSON), duration of each stage |

## Planned modules

| Module | Responsibility |
|---|---|
| Audio capture + VAD | Continuous recording, splitting into utterances, end-of-utterance timestamps |
| ASR | On-device Whisper (whisper.cpp binding); model size chosen by measurements on real phones |
| API client | Requests and responses as defined by the PoC server API (`/docs`); timeout and error handling |
| Action state | Event history and the current scenario step, kept on the phone and sent with every request |
| Event log | Local storage (e.g. SQLite) of recognised actions with timestamps; export |
| TTS | Polish system text-to-speech, a queue of prompts, pauses listening while speaking |

## Decisions to make

- State management approach (e.g. Riverpod, Bloc or plain `ChangeNotifier`) – record the choice as an ADR in `docs/adr/`.
- Whisper binding and model size – based on measurements on at least one Android phone and one iPhone.

## Revision history

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-10-26 | Planned design of the demo app |
