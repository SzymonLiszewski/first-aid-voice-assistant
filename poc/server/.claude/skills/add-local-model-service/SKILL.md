---
name: add-local-model-service
description: Use when adding a new inference server (LLM, ASR, embeddings) as a container in docker-compose.
---
> TEMPLATE – to be finished; refine after the first real local setup.

1. Add the service to `docker-compose.yml` under its own profile, with a pinned image tag and a healthcheck.
2. Add it to `docker-compose.gpu.yml` if it can use a GPU.
3. Add the matching URLs to `configs/*.yaml` and `.env.example`.
4. Document the service and its profile in `poc/server/README.md`, `poc/server/AGENTS.md` and `poc/server/docs/architecture.md`.
