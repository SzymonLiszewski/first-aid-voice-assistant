---
name: consultation-note
description: Use when the user gives raw notes from a thesis consultation with the supervisor (usually in Polish, pasted or as a file) and wants them turned into docs/consultations/YYYY-MM-DD.md. Translates to English, removes third-party names and informal remarks, and lists the action items.
---

Turn raw consultation notes into a note in `docs/consultations/` that follows the project's documentation rules (English, metadata header, revision history – see `CONTRIBUTING.md`). Consultation notes carry no author: neither in the header nor in the revision history.

## Input

- The raw notes: pasted text or a file path (e.g. a `.txt` file). Usually in Polish, often terse or in shorthand.
- The meeting date. Take it from the notes or the file name; if it is not there, ask the user. Do not guess.

## Steps

1. Read `docs/consultations/_template.md` and `docs/consultations/README.md`. Look at one existing note (e.g. `docs/consultations/2026-10-15.md`) to match the tone and level of detail.
2. If `docs/consultations/<date>.md` already exists, do not overwrite it: show the user what would change and ask whether to merge the new notes into it.
3. Translate the notes into English and sort every point into the template sections:
   - **Presented** – what the team showed or reported.
   - **Feedback and decisions** – the supervisor's remarks and decisions. Keep the supervisor's formal remarks (e.g. requirements for documents) clearly marked.
   - **Action items** – every task as a checkbox (`- [ ] Task – owner`); add the owner only if the notes name one.
   - **Next meeting** – date, time and form if the notes give them; otherwise "To be arranged".
   Remove sections that would stay empty, except **Action items** and **Next meeting**.
4. Write `docs/consultations/<YYYY-MM-DD>.md`:
   - header (no author): Created = the meeting date, Version = `0.1`,
   - revision history with the columns Version | Date | Changes (no author): one row `0.1 | <today> | Notes from the meeting`.
5. Add a row to the table in `docs/consultations/README.md` (date link + main topics in a few words), keeping the table sorted by date.

## Rules for the content

- **The repository is public.** Do not name third parties (people from other institutions, other researchers, contacts): describe them by role, e.g. "a contact at the Medical University of Gdańsk (GUMED)", "researchers at Gdańsk Tech working on Whisper". Refer to the supervisor as "the supervisor". Do not include e-mail addresses, phone numbers or other personal data.
- **Leave out informal, emotional or offensive remarks** and private comments; keep only facts, decisions and tasks. If such a remark carries a real task (e.g. "share a link with someone"), keep the task in neutral wording.
- **Do not invent anything.** Shorthand may be expanded only when the meaning is clear from the notes or from the project context (`docs/project/`). When a point is ambiguous, keep a literal translation and list it as a question in the summary for the user.
- Keep project-specific names as they are (model names such as Whisper, Bielik, PLLuM; tools; standards such as ERC, KMCR) and use the terms from `docs/project/glossary.md`.
- Units, dates (YYYY-MM-DD) and numbers stay exact.

## Summary for the user

After writing the files, reply in the user's language with:

1. the path of the created note,
2. the list of action items (so they can be copied to the task tracker),
3. what was left out or neutralised (names, remarks) – one line each,
4. ambiguous points that need the user's confirmation.

Do not commit; the user reviews the note first.
