# First-aid voice assistant

A voice assistant that supports people during emergency and first-aid actions. It listens to the person giving help, recognises the actions they perform (speech recognition + a large language model), records them with timestamps in an event log, and prompts the next steps according to prepared rescue scenarios.

The assistant is meant both for **paramedics** and for **laypeople** – bystanders who give first aid in the street. The project is developed as a master's thesis; its effectiveness is measured by how closely the automatically created event log matches a reference log on a corpus of staged rescue recordings.

> **Disclaimer.** This is a research prototype, not a medical device. Its answers are not medically validated and it does not replace emergency services. In a real emergency call **112**.

## Status

| Part | Status |
|---|---|
| `poc/server` – test server (FastAPI, LLM behind swappable providers) | working: the LLM can be tested with ready-made transcripts |
| `poc/mobile` – demo mobile app (Flutter) | not started |
| `apps/` – target application | not started |
| `knowledge/` – knowledge base (sources, scenarios) | being collected |
| `eval/` – evaluation (WER, event-log agreement) | not started |

## Repository map

```
first-aid-voice-assistant/
├── README.md            # this file
├── CONTRIBUTING.md      # branches, commits, pull requests, documentation rules
├── AGENTS.md, CLAUDE.md # project-wide rules for people and coding agents
├── docs/                # project documentation
│   ├── project/         #   overview, requirements, architecture, glossary
│   └── adr/             #   architecture decision records
├── poc/                 # proof of concept / demo
│   ├── server/          #   test server (Python, FastAPI) – has its own README, AGENTS.md and docs/
│   └── mobile/          #   demo mobile app (Flutter) – has its own README, AGENTS.md and docs/
├── apps/                # target application (server, mobile) – not started
├── knowledge/           # knowledge base shared by the PoC and the target app
├── eval/                # evaluation datasets, scripts and results
└── .github/             # GitHub configuration (workflows/ – none yet)
```

Every part (`poc/server`, `poc/mobile`, `apps/*`) is self-contained: it has its own `README.md` (how to run it), `AGENTS.md` (rules for working on it) and `docs/` (architecture and coding conventions).

## Quick start

The test server:

```bash
cd poc/server
docker compose up --build
```

Then open http://localhost:8000/dev. Details and options without Docker: [poc/server/README.md](poc/server/README.md).

## Documentation

- [Project overview](docs/project/overview.md)
- [Requirements](docs/project/requirements.md)
- [System architecture](docs/project/architecture.md)
- [Glossary](docs/project/glossary.md)
- [How to contribute](CONTRIBUTING.md)
