# 0001. Flutter for the mobile app

| | |
|---|---|
| **Created** | 2026-10-27 |
| **Status** | accepted |

## Context

The assistant needs a mobile app for Android and iOS. The team is small and cannot maintain two native code bases. The app has to:

- record audio continuously and detect speech,
- run speech recognition (Whisper) on the phone, so that it also works offline,
- read prompts aloud with Polish text-to-speech,
- keep a local event log and talk to the PoC server over HTTP.

Later it may also run a small language model on the phone (llama.cpp).

## Decision

The mobile app is written in **Flutter** (Dart), one code base for Android and iOS. The project lives in `poc/mobile/` (package `first_aid_voice_assistant`, application ID `io.github.szymonliszewski.first_aid_voice_assistant`).

## Alternatives considered

- **React Native** – also one code base for both platforms and has bindings for whisper.cpp and llama.cpp. Rejected because the team chose Flutter at the start of the project and the first backend documents already assumed it; neither option has a decisive technical advantage for this app.
- **Native apps (Kotlin + Swift)** – best access to platform APIs, but two code bases are too much work for the team and the time frame of the thesis.
- **Kotlin Multiplatform** – shares logic but still needs a separate UI for each platform and has a smaller ecosystem of ready-made plugins for audio and on-device models.

## Consequences

- One code base and one set of tests for Android and iOS.
- Native libraries (whisper.cpp, later llama.cpp) are used through Flutter plugins or `dart:ffi`; the choice of the Whisper binding is a separate decision based on measurements on real phones.
- iOS builds require a Mac with Xcode; on Windows the team builds and tests the Android version only.
- Team members need the Flutter SDK and the Android SDK (API 36) installed; setup is described in `poc/mobile/README.md`.
