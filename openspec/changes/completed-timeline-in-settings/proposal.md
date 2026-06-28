## Why

The Completed view currently exists as orphan code — defined but never wired into navigation. Meanwhile, Settings is a thin single-section form. Surfacing completed reminders as a timeline inside Settings gives users a natural place to review what they've done, while giving Settings more purpose.

## What Changes

- **SettingsView** gains a "Recently Completed" NavigationLink at the bottom, pushing to a timeline-styled Completed view
- **CompletedView** is rewritten from a grouped list to a visual timeline (vertical line + dots, sorted by completion date)
- **CompletedViewModel** is updated to expose timeline rendering data (per-item position indicators)
- **Destination labels** ("Will reappear in...") are removed from completed task rows (Apple approach)
- The existing `completed-view` spec is updated to reflect the new entry point, timeline visual, and removed destination label

## Capabilities

### New Capabilities
- _(none — this modifies an existing capability)_

### Modified Capabilities
- `completed-view`: Entry point changes from sidebar to Settings; visual changes from grouped list to timeline; destination labels removed

## Impact

- `TaskFlow/Features/Completed/CompletedView.swift` — major rewrite
- `TaskFlow/Features/Completed/CompletedViewModel.swift` — enhanced with timeline data structures
- `TaskFlow/Features/Settings/SettingsView.swift` — added NavigationLink + @Query
- `openspec/specs/completed-view/spec.md` — spec updates for new behavior
