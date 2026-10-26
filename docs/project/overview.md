# Project overview

| | |
|---|---|
| **Created** | 2026-10-26 |
| **Version** | 0.1 |

## Thesis topic

*A virtual voice assistant supporting rescue actions* – a master's thesis at Gdańsk University of Technology.

## Goal

To develop a virtual assistant that supports rescue actions. The assistant is based on a selected automatic speech recognition (ASR) system and a selected large language model (LLM). Its input is the voice of the people performing the rescue actions. The assistant:

1. records the time of each performed action,
2. writes it to an event log,
3. prompts the actions that still need to be done, according to prepared scenarios.

The assistant is tested on a provided corpus of recordings of staged rescue actions. Its effectiveness is measured by the agreement between the automatically created event log and the reference log.

## Users

Compared with the original topic, the project also targets laypeople:

| User | Needs |
|---|---|
| **Layperson** (a bystander giving first aid in the street) | Step-by-step guidance in simple language, reminders to call 112, help under stress, no medical knowledge required |
| **Paramedic** | Hands-free documentation of performed actions with timestamps, reminders of the next steps of a procedure, professional terminology |

## Scope

- Mobile app for Android and iOS, operated mainly by voice; the screen is auxiliary.
- Offline operation is a design goal: emergencies happen where there is no network (forests, mountains, basements, roads outside towns), and a cloud provider may become unavailable. Cloud models are used to improve quality when they are available.
- Knowledge comes from vetted sources (resuscitation and first-aid guidelines, rescue procedures) turned into rules and scenarios; the assistant suggests only steps that exist in the knowledge base.

## Research value

Comparing models (local vs cloud, different sizes) and the online vs offline mode on the same corpus of recordings shows how much log quality and latency independence from the network and external providers costs.

## Out of scope

- The assistant is a research prototype, not a certified medical device, and does not replace emergency services.
- No diagnoses and no drug dosing.

## Revision history

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-10-26 | First version, based on the thesis topic and the system concept document |
