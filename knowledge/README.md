# Knowledge base

Vetted first-aid and emergency-medicine knowledge that the assistant relies on. Shared by the PoC and the target application. The assistant suggests only steps that exist here.

| Folder | Content | In git |
|---|---|---|
| `raw/` | Original documents (guidelines, procedures, training materials) | **no** – may be under licences that forbid redistribution |
| [`sources/`](sources) | One entry per source: title, publisher, version/year, link, access date, scope (layperson / paramedic) | yes |
| [`scenarios/`](scenarios) | Machine-readable rules: the dictionary of rescue actions and the scenarios (JSON/YAML) | yes |

## Principles

- Every rule in `scenarios/` refers to its source (document and section) from `sources/`.
- Scenarios are state machines: steps, transition conditions (e.g. "is the person breathing?"), timers (e.g. change of the person doing compressions every 2 minutes), separate prompts for laypeople and paramedics.
- The action dictionary gives every action a code, a name, a level (layperson / paramedic) and colloquial synonyms (e.g. "uciskam", "masaż serca", "RKO"). The same codes are used in the event log and in the reference logs in `eval/`.
- Rules should be reviewed by a medical professional before they are used in an evaluation.
