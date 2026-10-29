# PoC mobile app

Demo mobile app of the first-aid voice assistant (Flutter, Android and iOS). **Not started yet** – this folder will hold the Flutter project.

## Planned scope

- **Start screen:** a large "Start helping" button, layperson / paramedic mode, a visible "call 112" button.
- **Action screen:** continuous listening, the current instruction in large text (also read aloud), listening / analysing / speaking indicator, action timer and 2-minute cycle counter, latest events.
- **Summary screen:** timeline of the recorded actions and export of the event log (JSON).
- **Debug panel (hidden):** transcript, raw model response and the duration of each stage.

Speech recognition (Whisper) runs on the phone; the transcript is sent to the [PoC server](../server). Details: [docs/architecture.md](docs/architecture.md). Coding conventions: [docs/conventions.md](docs/conventions.md).

## Running

To be filled in when the Flutter project is created (`flutter create`). Expected:

```bash
cd poc/mobile
flutter pub get
flutter run
```

Server address: from an Android emulator `http://10.0.2.2:8000`, from a physical phone the computer's LAN address.

Working rules: [AGENTS.md](AGENTS.md) and the project-wide [AGENTS.md](../../AGENTS.md).
