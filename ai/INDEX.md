# AI Context Index

Load in tiers. Stop as soon as you have enough to act.

| Tier | Load | When |
|---|---|---|
| 0 | `AGENTS.md` | Always (auto-loaded). Binding invariants live there. |
| 1 | This file | Before any repo navigation. |
| 2 | Exactly one doc below | Based on task. Do not preload all docs. |
| 3 | Listed source files from `REPO-MAP.md` | Only after tier 2. |

## Task → doc

| Task | Read |
|---|---|
| Architecture/navigation decision, new feature, SwiftUI structure | `ARCHITECTURE.md` |
| Finding a file, symbol, owner, or live vs legacy surface | `REPO-MAP.md` |
| Editing a View/ViewModel, dates, colors, schema, CloudKit | `CONVENTIONS.md` |
| Build, test, lint, CI, release, env vars, scripts | `OPERATIONS.md` |
| Blog, Dev.to, marketing copy, social posts | `CONTENT.md` |
| Machine-readable lookup (tooling) | `manifest.json` |

## Hard rules for agents

- Never recursively scan the repo. Use `REPO-MAP.md`, then open named files.
- `Features/Home/` and `Features/Tasks/` are legacy. Do not extend them; do not treat them as current navigation.
- `openspec/`, `content/`, `Docs/`, `CHANGELOG.md`, `.codex/`, `.amazonq/`, `.agents/tasks/archive/`, and `.ralph/` were removed as stale. Do not recreate or reference them.
- `Features/Tasks/Timeline/` has no surviving UI but its three helper files are used by live code. Do not delete them; do not add screens there.
- Do not commit `.derivedData/`, `DerivedData/`, `build/`, `.ralph/runs/`, or `.env`.
- Customer-facing name is **Wednesday Calendar**; `TaskFlow` is internal only.

## Keeping this index current

When adding a Swift file, delete a feature, or change a command, update `REPO-MAP.md` and `manifest.json` in the same PR. Regenerate the file list with:

```bash
git ls-files 'TaskFlow/*.swift' 'TaskFlow/**/*.swift'
```
