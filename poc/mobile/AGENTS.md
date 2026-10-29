# PoC mobile app – agent instructions

Project-wide rules (language, domain and safety, data, documentation) are in the root [`AGENTS.md`](../../AGENTS.md); this file adds the rules specific to the mobile app. Run all commands from `poc/mobile/`.

Status: not started. The Flutter project will be created here.

## Safety in this part

- The "call 112" button is always visible and works without the backend.
- When the server is unreachable or returns an error, the app says so plainly and points the user to 112. It never shows an invented instruction.
- While the app is speaking (TTS), listening is paused – otherwise the app hears itself and records its own instruction as a user action.

## Rules

- Requests to the server and responses from it follow the server API (Pydantic models in `poc/server`, browsable at `/docs` of the running server). Event-log entries follow `docs/project/architecture.md`.
- Event timestamps are taken at the **end of the utterance**, not when the server answers – otherwise server latency distorts the times compared with the reference log in the evaluation.
- The state of the action (event history, current scenario step) is kept in the app and sent with every request; the server does not keep sessions.
- Model files (Whisper weights) are not committed; document where to download them.
- Coding conventions: [docs/conventions.md](docs/conventions.md).

## Definition of done

`flutter analyze` and `flutter test` pass, the code is formatted with `dart format`, and `README.md` / `docs/` are updated if the structure or behaviour changed.
