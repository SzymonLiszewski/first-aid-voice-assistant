# PoC mobile app – coding conventions

| | |
|---|---|
| **Created** | 2026-10-26 |
| **Version** | 0.1 |

> Status: proposed. To be confirmed by the team when the Flutter project is created.

## Tooling

| Tool | Use | Command |
|---|---|---|
| Flutter / Dart SDK | build and run | `flutter run` |
| dart format | formatting (default style) | `dart format .` |
| flutter analyze | static analysis with `flutter_lints` (configured in `analysis_options.yaml`) | `flutter analyze` |
| flutter test | unit and widget tests | `flutter test` |

`flutter analyze` and `flutter test` must pass before a pull request is merged.

## Project structure (feature-first)

```
lib/
├── main.dart
├── app/            # app widget, routing, theme
├── features/       # one folder per feature: start/, action/, summary/, debug/
│   └── <feature>/  #   screens, widgets and state of that feature
├── services/       # audio + VAD, ASR (Whisper), TTS, API client, event log storage
└── models/         # data classes shared across features (events, API requests and responses)
test/               # mirrors lib/
```

## Dart style

- Follow [Effective Dart](https://dart.dev/effective-dart): `lowerCamelCase` for variables and functions, `UpperCamelCase` for types, `snake_case` for file names.
- Prefer `final` and immutable data classes; mark widgets `const` where possible.
- Keep widgets small: UI in widgets, logic in services or state classes, not in `build` methods.
- Data exchanged with the server is defined once in `models/` and matches the PoC server API (`/docs` of the running server).
- Everything is in English (identifiers, comments, logs); only user-facing texts shown in the app are in Polish.

## Errors

- Every network call has a timeout. On error or timeout the app shows a clear message and the "call 112" action – never an invented instruction.
- Use a logger (e.g. `package:logging`) instead of `print`; do not log full transcripts outside debug builds.

## Tests

- Unit tests for services and state (event log, timestamps, API client with a fake server).
- Widget tests for the key screens (the "call 112" button is always present).

## Revision history

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-10-26 | Proposed conventions |
