---
name: swap-model
description: Use when asked to try model X instead of model Y, e.g. "test Qwen instead of Llama" or "try Deepgram instead of Whisper".
---
> TEMPLATE – to be finished. Depends on `eval/run_eval.py` (repository root). Run the commands from `poc/server/`.

1. Create `configs/experiments/<asr>_<llm>.yaml` based on `configs/base.yaml`, changing only the requested part.
2. Start the needed compose profiles (`local-asr`) and pull the model (e.g. `docker compose exec llm ollama pull <model>`).
3. Run the evaluation with the new config (`run-eval` skill) and compare it with the base config.
4. Report the differences: quality, time to first token, cost per turn, and first-aid safety behaviour.
