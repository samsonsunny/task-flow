## Why

When a user opens the Today, Tomorrow, or a list view, all subtask trees and the overdue section render fully expanded. This creates visual overload — especially with many tasks — and contributes to anxiety when scanning what needs attention. A collapsed-by-default layout gives a calm overview; the user expands only what they need.

Additionally, `showOverdue` and `collapsedTasks` currently live in the ViewModel, but `onAppear` can recreate the ViewModel on tab switches — causing manual expand/collapse choices to be lost. Moving these UI toggle states to the View (as `@State`) fixes this and aligns with MVVM conventions.

## What Changes

- Subtask trees in `ReminderSegmentDetailView` and `ListDetailView` initialize collapsed by default
- The overdue section in the Today view initializes collapsed (`showOverdue = false`)
- `showOverdue` and `collapsedTasks` move from ViewModel to View `@State` — survives ViewModel recreation
- Collapse state resets on app restart (clean slate each morning)
- Manual expand/collapse choices persist across tab switches within a session

## Capabilities

### Modified Capabilities
- `task-subtasks`: Change default collapse state from expanded to collapsed; move collapse state to View
- `overdue-view`: Change default overdue section visibility from visible to collapsed; move to View

## Impact

- `TimelineViewModel.swift` — remove `showOverdue`, `collapsedTasks`, `toggleCollapse()`, `toggleShowOverdue()`
- `TimelineView.swift` — add `@State` for `showOverdue` and `collapsedTasks`, wire toggle logic
- `DetailViewModel.swift` — remove `collapsedTasks`, `toggleCollapse()`
- `DetailView.swift` — add `@State` for `collapsedTasks`, wire toggle logic
- `task-subtasks/spec.md` — update default state requirement
- `overdue-view/spec.md` — update default visibility requirement
