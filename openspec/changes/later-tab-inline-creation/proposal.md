## Why

The Later tab's Floating Add Button always sits as a `.bottomTrailing` overlay, covering the last list row. This creates friction when accessing lists near the bottom, and the FAB is the only way to create lists/groups — group creation is buried in a list's context menu, invisible to new users. Moving to inline creation rows eliminates the overlay problem and surfaces both list and group creation as first-class actions.

## What Changes

- Remove `ReminderFloatingAddButton` overlay from `ListsTabView`
- Add inline `+ New List` row at the bottom of the Lists section (always visible)
- Add inline `+ New Group` row at the bottom of the Groups section (always visible)
- Add `+` toolbar button in Lists and Groups section headers as a secondary creation CTA
- Add a sheet-based creation flow for lists with optional group assignment
- Add a sheet-based creation flow for groups with optional list assignment
- Inline "New Group…" / "New List…" option in the association picker opens a dedicated mini-sheet to create the other entity on the fly

## Capabilities

### New Capabilities

- `inline-list-group-creation`: Inline creation rows and sheet-based creation flows for lists and groups in the Later tab, with cross-association between lists and groups

### Modified Capabilities

None — this is new behavior, not a change to existing requirements.

## Impact

- `TaskFlow/Features/Lists/ListView.swift` — remove FAB overlay, add inline rows, add header buttons
- `TaskFlow/Features/Lists/` — new sheet for list/group creation with association picker and inline mini-sheet for on-the-fly creation
- The FAB is removed only from the Later tab; other tabs are unchanged
