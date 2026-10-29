# Requirements

| | |
|---|---|
| **Created** | 2026-10-26 |
| **Version** | 0.1 |

> Draft based on the system concept document and consultations. To be refined with the team and the supervisor.

## Functional requirements

| ID | Requirement |
|---|---|
| FR-1 | The app listens continuously during an action and converts speech to text (ASR). |
| FR-2 | The assistant recognises the rescue actions mentioned in the user's speech (LLM). |
| FR-3 | Every recognised action is written to the event log with its timestamp (the end of the utterance). |
| FR-4 | Based on the scenario and the actions done so far, the assistant prompts the next required step. |
| FR-5 | Prompts are read aloud (TTS), so the app can be used hands-free; the screen shows the current instruction. |
| FR-6 | The user chooses the mode: layperson or paramedic; prompts and vocabulary differ between the modes. |
| FR-7 | A "call 112" action is always available and is shown whenever the backend fails. |
| FR-8 | After the action, the user can review the event log and export it (e.g. to hand it over to emergency services or for documentation). |
| FR-9 | Core functions (listening, recognition, event log, prompts) also work without network access. |

## Non-functional requirements

| ID | Area | Requirement |
|---|---|---|
| NFR-1 | Safety | The assistant suggests only steps present in the knowledge base, never invents procedures, gives no diagnoses and no drug dosing. |
| NFR-2 | Safety | The assistant does not simply agree with the user; it checks statements against the scenario and corrects them. |
| NFR-3 | Latency | The prompt follows the end of an utterance quickly enough to guide an ongoing action; the end-to-end latency is measured. If the cloud does not answer within about 1.5 s, the local result is used. |
| NFR-4 | Availability | Loss of network during an action does not interrupt prompts or the event log; the user is not distracted with network messages. |
| NFR-5 | Platforms | Android and iOS from one code base. |
| NFR-6 | Language | Polish speech and prompts. |
| NFR-7 | Privacy | Recordings and logs may contain personal and health data (GDPR); they are stored locally and sent only where needed. |
| NFR-8 | Measurability | Every stage (VAD, ASR, server, LLM, TTS) can be timed, and every configuration can be evaluated on the recording corpus. |
| NFR-9 | Replaceability | ASR and LLM models can be swapped by configuration, without code changes, to compare them and to reduce dependence on a single provider. |

## Revision history

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-10-26 | First draft |
