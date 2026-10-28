# PoC mobile app – architecture

| | |
|---|---|
| **Created** | 2026-10-26 |
| **Version** | 0.7 |

> Status: the start screen and on-device speech recognition are implemented; the server connection and text-to-speech come next. Why Flutter: [ADR 0001](../../../docs/adr/0001-flutter-for-mobile-app.md).

## Goal of the demo

The demo checks that a voice conversation with the assistant works end to end:

1. **Speech recognition** – Whisper on the phone turns speech into text.
2. **Model answer** – the text goes to the PoC server, the language model answers.
3. **Voice answer** – the answer is read aloud.

## Flow

```
hold the talk button ─▶ microphone (16 kHz) ─▶ Whisper on the phone (live: while speaking) ─▶ release ─▶ user message
                                                                                           │
                       (next steps)   voice answer (TTS) ◀── answer ◀── PoC server (LLM) ◀─┘
```

## Screens

| Screen | Content | Status |
|---|---|---|
| Start | "Demo version" banner, what the demo checks, "Start test conversation" button, note about 112 | done |
| Test conversation | model status, partial text while speaking, user messages with timings, status line, push-to-talk button | done – user messages only |
| Settings | Whisper model (tiny / base / small), which models are downloaded | done – server address and voice check planned |

## Modules

| Module | File | Responsibility | Status |
|---|---|---|---|
| Entry point and wiring | `lib/main.dart`, `lib/config/dependencies.dart` | creates the real services and repositories (`AppDependencies`); tests build the app with fakes | done |
| Navigation | `lib/routing/router.dart` | route names, which screen each one opens | done |
| App shell | `lib/ui/core/` | root widget, theme, shared "demo" widgets | done |
| Start | `lib/ui/start/widgets/start_screen.dart` | start screen | done |
| Conversation | `lib/ui/conversation/` | `ConversationViewModel` (state, `ChangeNotifier`) talks only to `SpeechInput`; `ConversationScreen` | done – no server yet |
| Settings | `lib/ui/settings/`, `lib/data/repositories/settings_repository.dart` | settings screen; `SettingsRepository` keeps the chosen model, saved with `KeyValueStore` (`shared_preferences`) | done |
| Speech input | `lib/data/repositories/speech_input.dart` | `SpeechInput` interface; `WhisperSpeechInput`: microphone stream → whisper.cpp live session, warm-up, partial text | done |
| Voice recorder | `lib/data/services/voice_recorder.dart` | `VoiceRecorder` interface; `MicrophoneVoiceRecorder` (package `record`): 16 kHz mono PCM stream | done |
| Whisper | `lib/data/services/whisper_engine.dart` | `WhisperEngine` interface; `WhisperCppEngine` (package `whisper_ggml`): live sessions | done |
| Model files | `lib/data/services/model_store.dart` | `ModelStore` interface; `WhisperModelStore`: download with progress, timeouts, resume (HTTP `Range`), retries, size and SHA-256 check | done |
| Domain models | `lib/domain/models/` | `Utterance` (recognised utterance with timings), `AsrModel` (Whisper models with size and SHA-256) | done |
| Formatting | `lib/utils/format.dart`, `lib/utils/transcript.dart` | times in Polish format; transcript clean-up (Whisper tags, repetition loops) | done |
| Assistant client | `lib/data/services/`, `lib/data/repositories/`, `lib/data/model/` | sends the text to the server, returns the answer | planned |
| Text-to-speech | `lib/data/services/` | reads answers aloud, pauses recording while speaking | planned |

Services are hidden behind interfaces, so the view model is tested with fakes (`test/fakes/`) and a service can be swapped without touching the UI.

## Key behaviour

- **Push-to-talk:** recording runs while the button is held. Presses shorter than 0.5 s are ignored. If the button is released before recording has started (e.g. while the permission dialog is open), the recording is discarded.
- **Timestamps:** an utterance is stamped with the moment the user stopped speaking (button release), not with the end of recognition – the same rule as the event log.
- **Live recognition:** the microphone stream goes to a whisper.cpp live session that shows partial text while speaking – no audio file, no ffmpeg; audio captured before the session is ready is buffered, not lost. "tekst po X s" is the time from releasing the button to the final text.
- **Model:** the user picks tiny, base or small in the settings; the conversation uses the model chosen when it opens. A model is downloaded once on first use, streamed to a `.part` file with a progress bar; a stalled download (30 s without data) times out, an interrupted one resumes with HTTP `Range`, up to 3 attempts; the file is accepted only with the exact size and SHA-256 pinned in `AsrModel`. The model is loaded into memory once when the conversation opens (warm-up). After the download recognition works offline.
- **Transcript clean-up:** Whisper tags in square brackets are removed, a transcript that is only a sound description such as "(muzyka)" is dropped, and repetition loops are collapsed (a word 4+ times or a 2–3-word phrase 3+ times in a row).
- **Privacy:** no audio is written to disk.
- **Errors:** a failed download, missing microphone access or a recognition error is shown in Polish and the screen stays usable.

## Revision history

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-10-26 | Planned design of the demo app |
| 0.2 | 2026-10-27 | Flutter project created; link to ADR 0001 |
| 0.3 | 2026-10-27 | Simplified demo (start, test conversation, settings); start screen and on-device speech recognition implemented |
| 0.4 | 2026-10-27 | Settings screen with the choice of the Whisper model; own model download with progress |
| 0.5 | 2026-10-27 | Code structure aligned with the official Flutter architecture guide (ui / data / domain, config, routing, utils) |
| 0.6 | 2026-10-28 | Live recognition mode, verified and resumable model downloads, transcript clean-up |
| 0.7 | 2026-10-28 | File recognition mode removed; live recognition only |
