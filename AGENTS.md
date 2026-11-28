# TaskFlow — Agent Entry Point

Load `ai/INDEX.md` before navigating, then open **one** doc from the router below. Never recursively scan the repo. `ai/manifest.json` is the machine-readable form of this file.

## Always binding

- **MVVM:** Views observe and delegate; ViewModels mutate. `@Observable` only (never `ObservableObject`/`@Published`); `@Query` in views; `modelContext` from view; `update()` after `modelContext.save()`. Details: `ai/ARCHITECTURE.md`.
- **Product invariants (do not deviate):**
  1. Exactly two domains, Work and Personal (`ReminderListGroup`, locked by `AreaReconciler`). No third domain, no user-created/renamed/deleted domains.
  2. Root tabs are fixed: Today, Work, Personal, More. Never add project/list/group tabs or `Later`/`Tomorrow`/`Upcoming` surfaces.
  3. Lists are optional organization inside one domain; a list's domain is fixed at creation. No new model fields for this distinction.
  4. Today is cross-domain (overdue + due-today); future/undated tasks stay in their domain.
  5. One protected Inbox per domain, identified by domain + name `Inbox`; never add a persisted pointer.
  6. Extra groups fold into Work on launch, preserving lists and tasks.
  7. The Personal domain is labeled "Home" in the tab and page title; stored values stay `Work`/`Personal`.
  8. No sidebar or `NavigationSplitView` root.
- Docs beat code when they disagree; fix the code, not the invariants.
- **CloudKit:** any new field, relationship, or rename on an existing `@Model` requires a strictly higher `CURRENT_PROJECT_VERSION`. Details: `ai/CONVENTIONS.md`.
- **Naming:** "Wednesday Calendar" in customer-facing copy; "TaskFlow" is internal only.
- Never commit `.derivedData/`, `DerivedData/`, `build/`, `.ralph/runs/`, or `.env`.
- **Git:** rebase onto latest `origin/main` before making changes; keep pushes fast-forward. Never force-push `main`.

## Context router

| Task | Read |
|---|---|
| Architecture, navigation, new feature | `ai/ARCHITECTURE.md` |
| Find a file, symbol, or live vs legacy code | `ai/REPO-MAP.md` |
| Edit Swift, dates, colors, schema, CloudKit | `ai/CONVENTIONS.md` |
| Build, test, CI, release, env vars, scripts | `ai/OPERATIONS.md` |
| Blog, Dev.to, marketing copy | `ai/CONTENT.md` |

## Stale content

`openspec/`, `content/`, `Docs/`, `CHANGELOG.md`, `.codex/`, `.amazonq/`, `.agents/tasks/archive/`, and `.ralph/` were removed as stale. Do not recreate them; `ai/` docs are the source of truth.

## Quick commands

```bash
xcodebuild -project TaskFlow.xcodeproj -scheme TaskFlow -destination 'generic/platform=iOS Simulator' build
```
