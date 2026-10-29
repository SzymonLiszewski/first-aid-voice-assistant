# Target application

The target version of the first-aid voice assistant. **Not started yet.**

| Part | Description |
|---|---|
| [`server/`](server) | Production server |
| [`mobile/`](mobile) | Production mobile app (Android, iOS) |

Work starts here once the proof of concept in [`../poc`](../poc) has confirmed the approach. Code that proved itself in the PoC is moved here with `git mv` (to keep its history) or rewritten – the two versions are not developed in parallel.

Each part gets the same layout as in the PoC: its own `README.md` (how to run it), `AGENTS.md` (rules for working on it) and `docs/` (architecture and coding conventions).
