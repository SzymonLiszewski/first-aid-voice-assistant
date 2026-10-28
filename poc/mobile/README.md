# PoC mobile app

Demo mobile app of the first-aid voice assistant (Flutter, Android and iOS). **Status:** the start screen and on-device speech recognition (Whisper) work – the test conversation shows what you said. Next: answers from the server and reading them aloud. Why Flutter: [ADR 0001](../../docs/adr/0001-flutter-for-mobile-app.md).

| | |
|---|---|
| Package | `first_aid_voice_assistant` |
| Android application ID | `io.github.szymonliszewski.first_aid_voice_assistant` |
| iOS bundle ID | `io.github.szymonliszewski.firstAidVoiceAssistant` |
| Platforms | Android, iOS (iOS builds need a Mac with Xcode) |

## Scope of the demo

The demo checks that a voice conversation with the assistant works end to end.

| Screen / step | Status |
|---|---|
| **Start** – "demo version" banner, what the demo checks, button to the test conversation | done |
| **Test conversation** – hold the button, speak, see the text appear while speaking and the final text with its timings | done (user messages only) |
| Answers from the [PoC server](../server), read aloud | next |
| **Settings** – Whisper model (tiny / base / small) | done |
| Settings – server address, voice check | planned |

Details: [docs/architecture.md](docs/architecture.md). Coding conventions: [docs/conventions.md](docs/conventions.md).

## Setup (once)

1. Install the [Flutter SDK](https://docs.flutter.dev/install/archive) (stable), unpack it to a folder without spaces (e.g. `C:\Users\<you>\dev\flutter`) and add its `bin` folder to `PATH`.
2. Install the Android SDK with **Android SDK Platform 36**, **Android SDK Command-line Tools** and the **NDK (Side by side)** versions the build asks for (Android Studio → SDK Manager → SDK Tools → "Show Package Details"). The NDK compiles whisper.cpp.
3. In VS Code install the **Flutter** extension.
4. Check the setup: `flutter doctor` – *Flutter* and *Android toolchain* must be green.

## Running

All commands are run from `poc/mobile/`.

```bash
flutter pub get
flutter run
```

In VS Code: pick the device in the status bar and press F5. Use a **real phone** (USB debugging on): the emulator's microphone and performance do not reflect real use.

Server address (for the next step): from an Android emulator `http://10.0.2.2:8000`, from a physical phone the computer's LAN address.

## First run

- The Whisper model is chosen in **Settings** (default: base). When the test conversation opens with a model that is not on the phone yet, the app downloads it once with a progress bar – tiny ~78 MB, base ~148 MB, small ~488 MB (use Wi-Fi); interrupted downloads resume and every file is checked against its SHA-256. After that speech recognition works offline.
- The app asks for microphone access on the first press of the talk button.
- iOS: the deployment target is 15.6 (required by `whisper_ggml`). When CocoaPods creates `ios/Podfile` on a Mac, set `platform :ios, '15.6'` there too.

## Checks

```bash
dart format .
flutter analyze
flutter test
```

## Structure

Layers follow the official Flutter architecture guide – see [docs/conventions.md](docs/conventions.md).

```
lib/
├── main.dart                 # entry point: creates the dependencies, runs the app
├── config/                   # dependencies.dart – builds the real services (fakes in tests)
├── routing/                  # router.dart – route names and which screen each one opens
├── utils/                    # small shared helpers (format.dart – times in Polish format)
├── ui/                       # UI layer – feature-first
│   ├── core/                 #   app.dart (root widget), themes/, ui/ (shared widgets, demo banner)
│   └── <feature>/            #   start/, conversation/, settings/
│       ├── view_models/      #     state and logic of the screen (ChangeNotifier)
│       └── widgets/          #     <feature>_screen.dart and its widgets
├── data/                     # data layer – shared by features
│   ├── services/             #   wrap the outside world: microphone, Whisper, phone storage
│   ├── repositories/         #   source of truth exposed to view models (settings)
│   └── model/                #   API models (for the server connection)
└── domain/
    └── models/               # app data types (Utterance, AsrModel)
test/                         # tests mirroring lib/ (ui/, data/, utils/); fakes/ – fake services shared by the tests
```

Other folders: `android/`, `ios/` (platform projects: microphone permission, iOS 15.6), `docs/` (architecture, conventions), `pubspec.yaml` (dependencies: whisper_ggml, record, shared_preferences, crypto).

Working rules: [AGENTS.md](AGENTS.md) and the project-wide [AGENTS.md](../../AGENTS.md).
