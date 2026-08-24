# Architecture Concepts

Consolidated, feature-oriented documentation of TaskFlow's MVVM architecture. These docs capture the *concepts and invariants* that survive refactors — the individual PRDs they were distilled from are historical artifacts (see `.agents/tasks/archive/`).

## The shared MVVM contract

Every screen follows the same data flow. Full conventions: `openspec/standards/mvvm-conventions.md`.

```
View (@Query, UI state)  →  update()  →  ViewModel (@Observable)
        ↑                                        │
        └────────── renders from ←── mutations ──┘
                          via modelContext
```

1. **Views hold `@Query`** for SwiftData fetching; ViewModels never fetch.
2. **ViewModels are `@Observable` classes** receiving `modelContext` at init from the view's `@Environment(\.modelContext)`.
3. **Data enters the VM through `update(...)`**, called from `onAppear` / `onChange`. Because `@Model` objects compare equal by `persistentModelID`, property-only changes are invisible to `onChange` — every mutation must end with an explicit `update()` call to recompute derived state.
4. **All mutations live in the VM**: completion, quick capture, delete, move, schedule/reschedule. Views only observe and delegate.
5. **UI-only state stays in views**: `@FocusState`, sheet booleans, `@Environment(\.dismiss)`, `Timer.publish` (VM exposes `refreshNow()`).

## Cross-cutting concerns

| Concern | Owner | Rule |
|---|---|---|
| Sort order | `Utilities/SortOrderMidpoint.swift` | Midpoint/widen algorithm — insert between neighbors without renumbering everything |
| Time rounding | `Utilities/DateRounding.swift` | `nearestRoundedHour(from:)` rounds to nearest half hour; single source of truth for date/time toggles |
| Notifications | `Utilities/NotificationService.swift` | Scheduled on save/un-complete (when a time is set); cancelled on complete/delete |
| Tree flattening / collapse | `TaskTreeFlattener` + VM-local rebuild | Parent-child tasks render as a flat node list honoring collapsed state |
| Daily reorder persistence | VM read/write of daily order keys (`UserDefaults`) | Manual order per segment/day survives restarts |

## Concepts

| Doc | Feature area | ViewModels covered |
|---|---|---|
| [task-segments.md](task-segments.md) | Attention axis — Today/Tomorrow/Upcoming timeline + Completed | `TimelineViewModel`, `CompletedViewModel` |
| [lists-and-groups.md](lists-and-groups.md) | Home axis — Later tab lists/groups + list detail | `ListViewModel`, `DetailViewModel` |
| [editor-and-scheduling.md](editor-and-scheduling.md) | Task editor, draft pipeline, schedule picker | `EditorViewModel`, `DatePickerViewModel` |

The two-axis model these build on is defined in `openspec/specs/app-mental-model/spec.md`.

## Provenance

Consolidated in August 2026 from six completed MVVM-refactor PRDs (24 stories, all done):

- `mvvm-reminder-segment.json` → task-segments
- `mvvm-completed-view.json` → task-segments
- `mvvm-lists-tab.json` → lists-and-groups
- `mvvm-list-detail.json` → lists-and-groups
- `mvvm-reminder-editor.json` → editor-and-scheduling
- `mvvm-schedule-picker.json` → editor-and-scheduling

Those PRDs reference pre-restructure paths (`Features/Reminders/ViewModels/…`) that no longer exist; this folder and the actual code under `TaskFlow/Features/` are authoritative.
