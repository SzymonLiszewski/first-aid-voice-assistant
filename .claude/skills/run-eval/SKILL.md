---
name: run-eval
description: Use when comparing model or prompt variants on the evaluation set and updating the results table.
---
> TEMPLATE – to be finished. `eval/run_eval.py`, the datasets and the results table do not exist yet.

1. Run `uv run python eval/run_eval.py --config configs/experiments/<name>.yaml`.
2. Append the result to the shared results table in `eval/results/`, together with the full config and versions (model, prompt file, image tags).
3. Describe the differences and regressions against the base config.
4. Review the first-aid answers separately: safety failures (no 112, invented procedures, drug dosing, diagnoses) outweigh any quality gain.
