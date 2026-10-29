# PoC mobile app – architecture

| | |
|---|---|
| **Created** | 2026-10-26 |
| **Version** | 0.9 |

> Status: the whole demo loop works – on-device speech recognition with three selectable engines, answers from the PoC server over a WebSocket, read aloud while they are streamed (system voice or Piper); the user and the assistant take turns.

## Goal of the demo

The demo checks that a voice conversation with the assistant works end to end:

1. **Speech recognition** – a speech model on the phone turns speech into text, while the user speaks.
2. **Model answer** – the text goes to the PoC server, the language model answers.
3. **Voice answer** – the answer is read aloud.

## Flow

```
tap ─▶ microphone (16 kHz) ─▶ speech engine ─▶ utterances ─▶ 1.2 s without speech: microphone off ─▶ one question
                                                                                   │ ask (text + history), WebSocket
                                                                                   ▼
tap again ◀── speaker ◀── TTS, sentence by sentence ◀── sentence splitter ◀── delta, delta, … done ◀── PoC server (LLM)
```

## Screens

| Screen | Content | Status |
|---|---|---|
| Start | "Demo version" banner, what the demo checks, "Start test conversation" button, note about 112 | done |
| Test conversation | engine and voice status, partial text of the utterance in progress, one message per utterance with its time and timings, assistant answers growing while streamed (with "głos po X s · model Y s", "przerwano"), status line ("Asystent myśli / mówi…") with "Przerwij", tap-to-start / tap-to-stop button | done |
| Settings | speech engine (Parakeet, Vosk, Whisper tiny / base / small); voice (system / Piper) with "Odsłuchaj głos"; server address | done |

## Speech engines

| Engine | Speech detection | Recognition | `SpeechInput` | Libraries |
|---|---|---|---|---|
| Parakeet v3 (default) | Silero VAD | Parakeet TDT 0.6B v3 int8 (offline transducer) | `SegmentedSpeechInput` | sherpa-onnx |
| Whisper tiny / base / small | Silero VAD | Whisper ggml q5_1 | `SegmentedSpeechInput` | sherpa-onnx (VAD), whisper.cpp |
| Vosk small-pl | built into Vosk | Kaldi streaming model | `StreamingSpeechInput` | Vosk |

The engine is chosen in the settings; the conversation uses the engine chosen when it opens. `AppDependencies` builds the matching `SpeechInput`, so the view model and the screens do not depend on the engine.

## Modules

| Module | File | Responsibility | Status |
|---|---|---|---|
| Entry point and wiring | `lib/main.dart`, `lib/config/dependencies.dart` | creates the real services and repositories (`AppDependencies`) and picks the `SpeechInput` for the engine; tests build the app with fakes | done |
| Navigation | `lib/routing/router.dart` | route names, which screen each one opens | done |
| App shell | `lib/ui/core/` | root widget, theme, shared "demo" widgets | done |
| Start | `lib/ui/start/widgets/start_screen.dart` | start screen | done |
| Conversation | `lib/ui/conversation/` | `ConversationViewModel` (state, `ChangeNotifier`): end of the user's turn, utterances → one question, answers → screen and `AnswerSpeaker`, interrupting, fallback; `ConversationScreen` | done |
| Settings | `lib/ui/settings/`, `lib/data/repositories/settings_repository.dart` | settings screen; `SettingsRepository` keeps the speech engine, the voice and the server address, saved with `KeyValueStore` (`shared_preferences`) | done |
| Speech input | `lib/data/repositories/speech_input.dart` | `SpeechInput` interface (partial text, stream of utterances); `SegmentedSpeechInput` (microphone → VAD → transcriber → decoder) and `StreamingSpeechInput` (microphone → Vosk); both turn results into `Utterance` | done |
| Live transcription | `lib/data/repositories/segmented_transcriber.dart` | `SegmentedTranscriber`: decodes the utterance in progress for the partial text, decodes each finished speech region once for the message; one decode at a time | done |
| Voice recorder | `lib/data/services/voice_recorder.dart` | `VoiceRecorder` interface; `MicrophoneVoiceRecorder` (package `record`): 16 kHz mono PCM stream | done |
| Speech detection | `lib/data/services/speech_segmenter.dart` | `SpeechSegmenter` interface; `SileroSpeechSegmenter` (sherpa-onnx): finished speech regions and the start of the one in progress | done |
| Decoders | `lib/data/services/segment_decoder.dart`, `parakeet_decoder.dart`, `whisper_decoder.dart` | `SegmentDecoder` interface (samples → text); `ParakeetDecoder` (sherpa-onnx in a worker isolate); `WhisperDecoder` (whisper.cpp with speed settings) | done |
| Streaming recognizer | `lib/data/services/streaming_recognizer.dart` | `StreamingRecognizer` interface; `VoskStreamingRecognizer`: partial text, results with word times | done |
| Model files | `lib/data/services/model_store.dart` | `ModelStore` interface; `FileModelStore`: download of all files of an engine with progress, timeouts, resume (HTTP `Range`), retries, size and SHA-256 check, zip extraction | done |
| Domain models | `lib/domain/models/` | `Utterance` (recognised utterance with timings), `SpeechEngine` and `VoiceEngine` (with their files, sizes and SHA-256), `ChatMessage` and `AnswerEvent`, conversation entries (`UserMessage`, `AssistantMessage`) | done |
| Helpers | `lib/utils/` | times in Polish format; transcript clean-up; PCM bytes → samples; sentence splitter (Polish abbreviations) and markdown clean-up for reading aloud; WAV encoding; server address → WebSocket address | done |
| Assistant client | `lib/data/services/chat_socket.dart`, `lib/data/model/chat_protocol.dart`, `lib/data/repositories/assistant_repository.dart` | `ChatSocket` (package `web_socket_channel`); `AssistantRepository`: connects lazily and reconnects, sends `ask` with the history, turns server events into a stream of `AnswerEvent`s per question, `cancel`, timeouts (5 s to connect, 30 s without an event) | done |
| Speech output | `lib/data/repositories/speech_output.dart` | `SpeechOutput` interface (`prepare`, `prefetch`, `speak`, `stop`); `SystemSpeechOutput` (needs a `pl-PL` system voice); `SynthesizedSpeechOutput` (download → Piper → WAV → player; prepares the next sentence while the current one plays) | done |
| TTS services | `lib/data/services/text_to_speech.dart`, `speech_synthesizer.dart`, `audio_output.dart` | `FlutterTextToSpeech` (`flutter_tts`, completion via handlers); `PiperSynthesizer` (sherpa-onnx `OfflineTts` in a worker isolate); `AudioPlayersOutput` (`audioplayers`, speaker, mixes with recording) | done |
| Answer speaker | `lib/data/repositories/answer_speaker.dart` | `AnswerSpeaker`: takes the streamed text, speaks complete sentences in order, knows what was spoken, stops at once | done |
| Settings check | `lib/ui/settings/view_models/voice_check_view_model.dart` | "Odsłuchaj głos": prepares the chosen voice (downloads Piper) and reads a test sentence | done |

Services wrap one library or device each and are hidden behind interfaces; repositories combine them and hold the logic. The view model is tested with fakes (`test/fakes/`) and a service can be swapped without touching the UI.

Naming note: in this guide a *repository* holds the logic and a *service* wraps an outside source – roughly the reverse of the Spring-style backend layering (controller → service → repository).

## Key behaviour

- **Tap to talk:** the first tap starts recording, the second stops it, so the user does not have to hold the button (hands may be busy, e.g. during chest compressions). Taps while recording is starting are ignored.
- **One message per utterance:** a pause of about 0.5 s ends an utterance; it becomes a message at once, while recording continues. Continuous speech is split after 10 s. After the second tap the utterance in progress is finished and recognised.
- **Timestamps:** an utterance is stamped with the moment its speech ended, computed from its position in the recording – not with the tap or the end of recognition. This matches the rule for the event log. "tekst po X s" is the time from the end of the speech to the text.
- **Only speech is decoded (Parakeet, Whisper):** Silero VAD marks speech; silence and pauses never reach the decoder, which prevents Whisper from inventing text from silence and saves battery. While someone speaks, the utterance in progress is decoded about every 0.5 s for the partial text; a finished utterance is decoded once more in full. Only one decode runs at a time, so delays do not pile up.
- **Vosk:** audio goes to Vosk chunk by chunk; Vosk returns partial text and detects the end of an utterance itself. Message times come from Vosk word times.
- **Whisper settings:** language `pl`, greedy decoding (best-of 1, beam 1, no temperature fallback), no context, single segment, no timestamps, 4 threads, audio context proportional to the utterance length; utterances shorter than 1.1 s are padded with silence.
- **Model download:** an engine is downloaded once on first use, file by file, streamed to `.part` files with a progress bar; a stalled download (30 s without data) times out, an interrupted one resumes with HTTP `Range`, up to 3 attempts; a file is accepted only with the exact size and SHA-256 pinned in `SpeechEngine`; the Vosk zip is extracted and deleted. The models are loaded once when the conversation opens and warmed up with one second of silence. After the download recognition works offline.
- **Transcript clean-up:** tags in square brackets are removed, a transcript that is only a sound description such as "(muzyka)" is dropped, and repetition loops are collapsed (a word 4+ times or a 2–3-word phrase 3+ times in a row).
- **Answer while it is generated:** every utterance is sent at once as an `ask` with the conversation history. Streamed text is added to the assistant's message on the screen and split into sentences; a sentence is spoken as soon as the next one starts (or the answer ends), so the first sentence is heard while the model is still writing. Piper prepares the next sentence while the current one plays.
- **History:** the app keeps the conversation. Consecutive messages of the same speaker are joined; an interrupted answer is included only as far as it was spoken; answers that were not heard are left out. Words said before the answer starts are therefore asked together with the previous ones.
- **Taking turns:** after each utterance the app waits 1.2 s; new speech (partial text) cancels the wait, otherwise the microphone stops by itself and everything said in the turn is asked as one question. The button can also stop the turn by hand. While the assistant answers (thinking or speaking) the microphone is off and the talk button is disabled ("Poczekaj, aż asystent skończy"); "Przerwij" stops the answer ("przerwano", cancelled on the server).
- **Reading aloud:** markdown marks and list numbers are removed before a sentence is spoken (small models ignore the "no markdown" rule of the prompt); the screen shows the text as received.
- **Timings shown:** "głos po X s" – from the end of the user's speech to the first sound of the answer; "model Y s" – time to the first token on the server.
- **No server:** a failed connection, a server error or 30 s without an event ends the answer with a fixed message that is also spoken: no connection, call 112.
- **Privacy:** no recorded audio is written to disk (Piper's synthesized sentences may pass through a temporary file on iOS).
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
| 0.8 | 2026-10-29 | Three speech engines (Parakeet via sherpa-onnx, Vosk, Whisper via whisper.cpp); Silero VAD so that only speech is decoded; one message per utterance; tap to start and stop |
| 0.9 | 2026-10-29 | Server connection over a WebSocket; answers shown and read aloud while streamed; two voices (system, Piper); turn taking with automatic end of the user's turn; settings for voice and server |
