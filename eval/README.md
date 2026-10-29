# Evaluation

Measurements of the assistant on the corpus of staged rescue recordings. This is where the results for the thesis come from.

| Folder | Content | In git |
|---|---|---|
| `datasets/` | Recordings, transcripts and reference event logs | **no** – recordings may contain personal data (GDPR) |
| `scripts/` | Evaluation scripts | yes |
| `results/` | Results table and the configuration of every run | yes |

## Planned metrics

| Metric | What it measures |
|---|---|
| WER / CER | Quality of speech recognition, with Polish text normalisation (case, punctuation, numbers) |
| Event-log agreement | How well the automatic log matches the reference log: events are matched by action code within a time tolerance (±N s); precision, recall, F1 and the mean time error |
| Latency | Time from the end of an utterance to the voice prompt, and per stage (VAD, ASR, server, LLM, TTS) |
| Safety | Cases where the model agrees with a wrong statement, invents a procedure or omits the call to 112 |

Results are reported in one consistent format (either percentages or decimal fractions). Every entry in `results/` records the full configuration: models and their versions, prompt file, knowledge-base version.
