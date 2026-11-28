# TaskFlow — Agent Entry Point

`AGENTS.md` is the only agent guidance doc. `ai/manifest.json` indexes the live source areas, key files, and commands. Read only the files you need; do not recursively scan the repo.

## Always binding

- **MVVM:** Views observe and delegate; ViewModels mutate. `@Observable` only (never `ObservableObject`/`@Published`); `@Query` in views; `modelContext` from view; `update()` after `modelContext.save()`.
- **Product invariants (do not deviate):**
  1. Exactly two domains, Work and Personal (`ReminderListGroup`, locked in `MainTabView.ensureDomains()`). No third domain, no user-created/renamed/deleted domains.
  2. Root tabs are grouped and fixed, in order: Tasks group holds Personal (labeled "Home"), then Work; Search is a separate system search-role tab. Never add project/list/group tabs or `Later`/`Tomorrow`/`Upcoming` surfaces.
  3. Lists are optional organization inside one domain; a list's domain is fixed at creation. No new model fields for this distinction.
  4. Overdue and due-today tasks appear within their own domain; future/undated tasks stay in their domain.
  5. One protected Inbox per domain, identified by domain + name `Inbox`; never add a persisted pointer.
  6. Extra groups fold into Work on launch, preserving lists and tasks.
  7. The Personal domain is labeled "Home" in the tab and page title; stored values stay `Work`/`Personal`.
  8. No sidebar or `NavigationSplitView` root.
- Keep docs and code in sync; fix drift instead of preserving stale documentation. Product invariants are binding.
- **CloudKit:** any new field, relationship, or rename on an existing `@Model` requires a strictly higher `CURRENT_PROJECT_VERSION`. Current schema: `TaskFlowSchemaV10` in `TaskFlow/Models/TaskItem.swift`.
- **Naming:** "Wednesday Calendar" in customer-facing copy; "TaskFlow" is internal only.
- Never commit `build/`, `DerivedData/`, `.derivedData/`, `.ralph/`, `.email-agent/`, or `.env`.
- **Git:** rebase onto latest `origin/main` before making changes; keep pushes fast-forward. Never force-push `main`.

## Current layout

`ai/manifest.json` is the source of truth for live paths. Files and folders not listed there are not part of the current app.

## Quick commands

```bash
xcodebuild -project TaskFlow.xcodeproj -scheme TaskFlow -destination 'generic/platform=iOS Simulator' build
```
