---
name: pr-description
description: Use when the user asks for a pull request title and description (or "opis PR-a", "opis MR-a") for the current branch or a named branch. Produces a short title and a plain bullet list of what changed, in the project's style.
---

Write a pull request title and description in the style the team uses: a title plus a short bullet list of changes, nothing else.

## Steps

1. Find the branch and its base: the current branch unless the user names one; the base is `main` unless the user says otherwise. Run `git fetch` first so the base is current.
2. Collect what the branch changes:
   - `git log --oneline <base>..<branch>` – the commits,
   - `git diff --stat <base>...<branch>` – the files,
   - read the diff of files whose purpose is not clear from their names.
   Describe only what is committed on the branch; ignore uncommitted changes in the working tree and mention them in one line if they look like they belong to the PR.
3. Group the changes by what they do for the project (a feature, a move, a new folder, a fix), not file by file.
4. Write the result (format below) and give it to the user. Do not create or edit the pull request unless the user asks.

## Format

Title – one line, imperative mood, up to about 70 characters, no trailing period:

```
Restructure repository into docs, PoC and target app
```

Description – only a bullet list, no headings or sections (no "What", "Why", "Tested"):

```markdown
- Move the existing backend to `poc/server/` (with `git mv`, history kept); server commands now run from there
- Add `poc/mobile/` for the demo app and `apps/` for the target app
- Add `docs/` with project documentation, ADRs and consultation notes
```

## Rules

- English only (project rule), even when the conversation is in Polish.
- 3–7 bullets; each starts with a verb in the imperative mood: Add, Move, Update, Fix, Remove, Rename.
- One bullet per change that matters to a reviewer; skip formatting, lock files and other trivia.
- Name paths and identifiers in backticks.
- If a change affects how others work (commands, setup, moved files, new requirements such as an SDK version), say it inside the relevant bullet – there is no separate notes section.
- No task-tracker keys (e.g. Jira IDs) in the title or the description.
- Do not invent: every bullet must be backed by the diff.
