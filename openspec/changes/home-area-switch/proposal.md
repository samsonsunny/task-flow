## Why

The current sidebar page ("My Lists") is list *organisation* wearing a capture bar's clothes. It renders a list-of-lists, and a root-level `safeAreaInset` capture bar floats beneath it with no target indicator. A user sees a "+" for new list, then a second "+" in a field that says "Add a task…" — and reads the bar as list creation. Meanwhile the two areas that actually define the product, **Work** and **Personal**, are buried in `DisclosureGroup`s in a sidebar, and the capture target silently resolves to the *first* area's Inbox (`resolveCaptureBucket`), so a Personal user capturing from Today drops the task into Work with no signal.

The fix is to stop treating areas as an organisational detail and make them the app's top-level mode: **Home is the root, Work/Personal is a switch at the top, and that switch drives both what you see and where you capture.**

## What Changes

- **Home becomes the root of a single `NavigationStack`.** The `NavigationSplitView`, the "My Lists" sidebar, and the sidebar's time-segment rows are removed. `HomeView` is the landing surface.
- **The navigation title is removed and replaced by the area switcher.** No "Home" title — the page has two states, not one identity. Two pills (Work / Personal) sit in a compact navigation bar as the header, so the active area is always visible and the mode reads as first-class.
- **Home is both capture and view.** A capture bar pinned to the bottom targets the selected area; below it, all of that area's tasks are listed **grouped by list**, with the area's Inbox bucket pinned first.
- **Exactly two areas are enforced.** `ReminderListGroup` gains an `isLocked` flag. Work and Personal are locked: not renameable, deletable, or reorderable. All area-creation UI is removed.
- **(BREAKING) Extra areas are merged into Work, silently.** A recurring reconciler reparents every list from a non-locked area into Work, moves foreign Inbox-bucket *tasks* into Work's bucket by pointer, then deletes the emptied areas. No `TaskItem` is ever created, deleted, or modified — only `reminderList` pointers move.
- **(BREAKING) The `NavigationSplitView` root is removed**, reverting `lists-sidebar-split`'s container decision while keeping its capture-bar work.
- **Time views become area-scoped pushed screens.** Today / Tomorrow / Upcoming are pushed from a Home summary block and show only the selected area's work. To prevent silently hidden deadlines, a **cross-area nudge row** surfaces due-today/overdue counts belonging to the *other* area, and the app icon badge stays **global**.
- **Capture gets an explicit target.** `CaptureTarget.inbox` (the first-area fallback) is replaced by `CaptureTarget.area(...)`, and the bar gains an always-visible target chip whose menu is grouped by area. This is the direct fix for the reported confusion.
- **Tasks can move between areas** via the editor's list picker, which remains sectioned by area.
- **Dead code removed:** `QuickCaptureRow` (zero references), `GroupCreationSheet`, `MiniCreationSheet`, and the list sidebar.
- `deleteGroup` — which today deletes every list *and every task* in an area with no guard — is deleted outright.

## Capabilities

### New Capabilities

- `home-surface`: Home as the app root — the area-switch header, capture-bar ownership, tasks grouped by list with the Inbox bucket pinned first, the Today/Overdue summary block, the cross-area nudge row, area-scoped time views, and the single-`NavigationStack` navigation model.
- `area-locking`: Exactly two locked areas (Work, Personal) — the `isLocked` flag, the Work-identification rule, the silent merge of extra areas into Work, the reconciler contract, removal of all area CRUD UI, and cross-area task moves.

### Modified Capabilities

- `app-mental-model`: The two-axis model gains a home selector — the area switch is how the "where" axis is chosen, and Home is the surface where both axes meet.
- `tab-bar-navigation`: Root navigation requirements currently describe a 4-tab `TabView` that no longer exists; replaced by the single-`NavigationStack` model with Home as root.
- `areas-inbox`: Protection extends from the bucket to the whole area; capture-target resolution changes from first-area fallback to explicit selected area.
- `list-groups`: Group CRUD, group reordering, and move-to-group are removed; group sections become per-area list sections on Home.
- `list-management`: List reordering moves from the sidebar to Home; list creation no longer offers a group picker.
- `inline-list-group-creation`: The group-creation sheet and mini-sheet are deleted.
- `list-picker`: Becomes the sanctioned cross-area retarget surface, retaining area-sectioned display.
- `quick-capture`: Dead `+`/FAB/inline-row requirements are removed; capture targets the selected area via the bar's target chip.
- `overdue-view`: No longer a sidebar filter; overdue is area-scoped with the cross-area nudge.
- `completed-view`: Currently specifies UI nothing can reach — `MoreView` has no entry point; wired into Home's overflow menu.
- `bulk-editing`: Dead FAB-hidden and quick-capture-disabled requirements are removed.
- `task-count-badge`: Stated explicitly as global, so area scoping never leaks into the badge.

## Impact

- `TaskFlow/Models/TaskItem.swift` — add `isLocked` to `ReminderListGroup` in the latest schema version (V10); no `migrationPlan:` per AGENTS.md.
- `TaskFlow/Models/AreaReconciler.swift` — add `reconcileLockedAreas(in:)`; `seedDefaultAreas` sets `isLocked`; `resolveCaptureBucket` becomes area-scoped.
- `TaskFlow/App/ContentView.swift` — invoke the reconciler on appear.
- `TaskFlow/Features/Home/` — new `HomeView.swift` + `HomeViewModel.swift`.
- `TaskFlow/Features/MainTabView.swift` — `NavigationSplitView` → `NavigationStack(path:)`; `HomeView` root; `.navigationDestination` for segments and lists.
- `TaskFlow/Features/Lists/ListView.swift` — deleted (`ListsSidebarView`).
- `TaskFlow/Features/Lists/ListViewModel.swift` — area CRUD deleted; list ops guarded against locked parents.
- `TaskFlow/Features/Lists/{GroupCreationSheet,MiniCreationSheet}.swift` — deleted.
- `TaskFlow/Features/Lists/ListCreationSheet.swift` — group picker removed.
- `TaskFlow/Views/Components/{CaptureBar,CaptureBarViewModel}.swift` — `CaptureTarget.area`; target chip.
- `TaskFlow/Views/Components/QuickCaptureRow.swift` — deleted (dead).
- `TaskFlow/Previews/TaskPreviewData.swift` — add a both-areas fixture; every existing fixture seeds Work only.
- `TaskFlow/App/AppState.swift` — in-memory `selectedArea`, defaults to Work, never persisted.
- Tests — 3 UI helpers and 8 UI tests in `TaskFlowUITests`/`TaskFlowSubtasksUITests` are sidebar-dependent and must be rewritten; new area-lock and merge tests.
- Stale changes — `single-page-home` (0/25 tasks, superseded design) and `fab-visibility-behavior` (FAB no longer exists) should be cancelled; `lists-sidebar-split` finished and archived; `ipad-mac-release/tasks.md:10,20` references the sidebar and `columnVisibility` and must be amended.
