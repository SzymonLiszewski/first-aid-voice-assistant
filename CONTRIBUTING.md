# Contributing

## Language

Everything in this repository is written in English: code, comments, commit messages, pull requests and all documentation. The only exception is end-user-facing content in Polish, such as system prompts and domain glossaries used by the assistant.

## Branches

- `main` is always in a working state. Nobody pushes to it directly; changes go through pull requests.
- Create a short-lived branch per change, named `<type>/<short-description>`, for example `feature/vad-segmentation`, `fix/dev-chat-timeout`, `docs/consultation-2026-10-15`.
- Types: `feature`, `fix`, `docs`, `refactor`, `test`, `chore`.

## Commits

- One logical change per commit.
- Subject line in the imperative mood, up to about 70 characters, no trailing period: `Add Whisper provider for on-device transcription`.
- If the change needs explanation, add a body after an empty line: what changed and why, not how.
- Do not commit secrets (`.env`), model files (`*.gguf`, `*.bin`) or evaluation recordings.

## Pull requests

- Keep pull requests small and focused on one topic.
- Title in the imperative mood (like a commit subject); description as a short bullet list of changes, without sections (skill `pr-description`).
- At least one other team member reviews and approves the pull request before merging.
- Run the checks of the part you changed locally before asking for a review (see its `README.md`).
- Update the documentation of the part you changed (`README.md`, `docs/`) in the same pull request.
- Prefer "Squash and merge" so that `main` keeps one commit per pull request.

## Documentation

- Project-wide documentation lives in `docs/`; documentation of a single part lives in that part's `docs/` folder.
- Every document in a `docs/` folder starts with a metadata header and ends with a revision history:

  ```markdown
  | | |
  |---|---|
  | **Created** | YYYY-MM-DD |
  | **Version** | 0.1 |

  ...

  ## Revision history

  | Version | Date | Changes |
  |---|---|---|
  | 0.1 | YYYY-MM-DD | First version |
  ```

- Architecture decisions are recorded as short ADRs in `docs/adr/` (see [docs/adr/README.md](docs/adr/README.md)).
