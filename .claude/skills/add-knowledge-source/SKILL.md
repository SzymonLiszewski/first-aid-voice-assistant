---
name: add-knowledge-source
description: Use when adding documents (e.g. first-aid guidelines) to the knowledge base for RAG.
---
> TEMPLATE – to be finished. RAG is disabled and `scripts/ingest.py` does not exist yet.

1. Put the raw documents in `knowledge/` (or link to them). Prefer vetted sources, e.g. current resuscitation guidelines; record the source and date.
2. Ingest into a new collection version (`kb_v2`) with `scripts/ingest.py`; never overwrite the active one.
3. Refresh `configs/domain_terms.txt` with new terms.
4. Run the retrieval eval (recall@k, MRR) and compare answers with and without RAG.
