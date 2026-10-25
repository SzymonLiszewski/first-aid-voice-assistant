---
name: add-asr-provider
description: Use when adding a new speech-to-text (ASR) provider, batch or streaming, to the voice assistant backend.
---
> TEMPLATE – to be finished. The `ASRProvider` interface and the audio pipeline do not exist yet; fill in the details when they do.

1. Add the `ASRProvider` interface to `app/providers/base.py` if it is still missing (`transcribe` for batch, `transcribe_stream` for streaming).
2. Create `app/providers/asr/<name>.py`, register it, and map the language and the hotwords from `configs/domain_terms.txt`.
3. Add a config in `configs/experiments/` and keys to `.env.example`.
4. Add the provider to the contract tests (output format, errors, timeout, cancellation).
5. Run a short eval on ~10 recordings and compare WER, including medical and emergency terms.
