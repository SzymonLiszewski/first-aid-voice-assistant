# PoC mobile app – coding conventions

| | |
|---|---|
| **Created** | 2026-10-26 |
| **Version** | 0.4 |

> Based on the official [Flutter architecture guide](https://docs.flutter.dev/app-architecture/case-study): MVVM with a UI layer (views + view models), a data layer (repositories + services) and a domain layer (models).

## Tooling

| Tool | Use | Command |
|---|---|---|
| Flutter / Dart SDK | build and run | `flutter run` |
| dart format | formatting (default style) | `dart format .` |
| flutter analyze | static analysis with `flutter_lints` (configured in `analysis_options.yaml`) | `flutter analyze` |
| flutter test | unit and widget tests | `flutter test` |

`flutter analyze` and `flutter test` must pass before a pull request is merged.

## Project structure

The UI layer is organised by feature; the data and domain layers by type, because services and repositories are shared by features.

```
lib/
├── main.dart                 # entry point: creates the dependencies, runs the app
├── config/                   # dependencies.dart – builds the real services for the chosen engine (fakes in tests)
├── routing/                  # router.dart – route names and which screen each one opens
├── utils/                    # small shared helpers (times in Polish format, transcript clean-up, PCM conversion)
├── ui/                       # UI layer – feature-first
│   ├── core/                 #   app.dart (root widget), themes/, ui/ (shared widgets, demo banner)
│   └── <feature>/            #   start/, conversation/, settings/
│       ├── view_models/      #     state and logic of the screen (ChangeNotifier)
│       └── widgets/          #     <feature>_screen.dart and its widgets
├── data/                     # data layer – shared by features
│   ├── services/             #   wrap the outside world: microphone, speech libraries, downloads, phone storage
│   ├── repositories/         #   logic exposed to view models (speech input, settings)
│   └── model/                #   API models (for the server connection)
└── domain/
    └── models/               # app data types (Utterance, SpeechEngine)
test/                         # tests mirroring lib/ (ui/, data/, utils/); fakes/ – fake services shared by the tests
```

- **View** (`*_screen.dart`) only draws and passes user actions to its view model.
- **View model** (`*_view_model.dart`) holds the state of one screen and calls repositories or services; it never imports Flutter widgets.
- **Service** wraps one outside thing (a plugin, the network, storage) behind an interface, so tests can use fakes.
- **Repository** is the source of truth for some data and the place where several services are combined. Note: this is roughly the reverse of Spring-style backend naming, where the service holds the logic and the repository accesses the data.
- Folders without code yet keep a `.gitkeep`.

## Dart style

- Follow [Effective Dart](https://dart.dev/effective-dart): `lowerCamelCase` for variables and functions, `UpperCamelCase` for types, `snake_case` for file names.
- Prefer `final` and immutable data classes; mark widgets `const` where possible.
- Keep widgets small: UI in widgets, logic in services or state classes, not in `build` methods.
- Data exchanged with the server is defined once in `data/model/` and matches the PoC server API (`/docs` of the running server).
- Everything is in English (identifiers, comments, logs); only user-facing texts shown in the app are in Polish.

## Errors

- Every network call has a timeout (WebSocket: 5 s to connect, 30 s without an event). On error or timeout the app shows and says a clear message with the "call 112" action – never an invented instruction.
- Use a logger (e.g. `package:logging`) instead of `print`; do not log full transcripts outside debug builds.

## Tests

- Unit tests for services and state (event log, timestamps, API client with a fake server).
- Widget tests for the key screens (the "call 112" button is always present).

## Revision history

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-10-26 | Proposed conventions |
| 0.2 | 2026-10-27 | Structure aligned with the official Flutter architecture guide |
| 0.3 | 2026-10-29 | Structure updated for the speech engines; note on service and repository naming |
| 0.4 | 2026-10-29 | WebSocket timeouts; the fallback message is also spoken |
