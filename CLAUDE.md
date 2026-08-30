# CLAUDE.md — TrackGoa Project Operating Manual

You are the implementation engineer for **TrackGoa**, a flagship Flutter application for real-time public bus tracking in Goa.

Before every task:

1. Read `TRACKGOA_MASTER_PROMPT.md`.
2. Preserve the existing architecture.
3. Implement only the requested phase.
4. Never modify unrelated files.

---

## Current Project State

Repository: TrackGoa

Current completed phases:

* ✅ Phase 1 — Foundation
* ✅ Phase 2 — Data Layer
* ✅ Phase 3 — Premium Home Experience

Next phase:

* ⏳ Phase 4 — Interactive Routes Experience

Latest stable branch:

* `main`

---

## Protected Architecture

Never change these folders without explicit instruction:

* `lib/core/`
* `lib/data/`
* `lib/features/`

Current architecture:

`DataSource → Repository → Riverpod Provider → UI`

Never bypass repositories.

---

## UI Direction

Design inspiration:

* Google Maps
* Uber
* Citymapper
* Moovit

Style:

* Mobile-first
* Premium
* Glassmorphism
* Soft shadows
* Rounded corners
* Smooth 150–250ms animations

---

## Performance Rules

Especially important for maps.

* Bus markers should update independently.
* Don't rebuild entire screens.
* Use `select()` when appropriate.
* Prefer reusable widgets.

---

## Git Rules

Never:

* commit
* push
* rename architecture folders
* delete project structure

Only modify code requested for the current phase.

---

## Before finishing any task

Always:

* Run `flutter analyze`
* Run `flutter test`
* Summarize every changed file
* Explain why each change was made
