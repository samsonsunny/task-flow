## Why

The "Move to List" context menu action shows all lists in a single flat list with no organization — no groups, no separators, no clear ordering. As users create more lists and groups, this becomes increasingly confusing. The group structure exists in the data model (`ReminderListGroup`) but is ignored in the context menu.

## What Changes

- Make "Move to List" context menu group-aware: render groups as `Section` separators in the SwiftUI `Menu`, with the Inbox pinned at top, followed by grouped lists under their group name, then ungrouped lists at the bottom
- Add `ListSection` model to ViewModels to represent structured list data for the menu
- Update `TaskRowView` to render sectioned list menu
- Add unit tests for the new list section grouping logic
- The change is purely visual/organizational — no data model changes, no new relationships

## Capabilities

### New Capabilities
- `context-menu-list-sections`: Structured grouping of lists in the "Move to List" context menu, using the existing `ReminderListGroup` model to organize lists into sections

### Modified Capabilities

- *None* — no existing spec covers the context menu list behavior

## Impact

- `TaskRowView.swift` — context menu rendering changes from flat `ForEach(availableLists)` to sectioned rendering
- `TimelineViewModel.swift` — `otherLists` replaced with structured `listSections`
- `DetailViewModel.swift` — same
- `TaskNodeView.swift` — passes through new structured types
- New types: `ListSection` model (or similar) shared between ViewModels
- New tests for list section grouping
