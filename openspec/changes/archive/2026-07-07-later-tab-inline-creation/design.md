## Context

The Later tab (`ListsTabView`) currently has a `ReminderFloatingAddButton` overlay at `.bottomTrailing` that opens a "New List" alert with a text field. Group creation is only accessible via a list's context menu ("Create New Group") — invisible to new users and requiring a list to exist first. The FAB covers the last list row, creating friction.

The FAB action (alert with text field) will be replaced by sheet-based creation flows that also support list↔group association. The FAB is removed from this view entirely.

## Goals / Non-Goals

**Goals:**
- Remove the FAB overlay from `ListsTabView` to eliminate the content-covering problem
- Add an inline "+ New List" row at the bottom of the Lists section (always visible, even when empty)
- Add an inline "+ New Group" row at the bottom of the Groups section (always visible, even when empty)
- Add a `+` button in the Lists and Groups section headers as a secondary creation CTA
- Provide a sheet-based creation flow for lists with optional group assignment via a Menu picker
- Provide a sheet-based creation flow for groups with optional list assignment via a Menu picker
- Allow on-the-fly creation of a group during list creation (and vice versa) via a mini-sheet
- Use toolbar-based Cancel/Create buttons in the nav bar (not bottom bar) to avoid keyboard overlap

**Non-Goals:**
- Changes to other tabs (Today, Tomorrow, Upcoming, List Detail)
- Changes to the FAB component itself (`ReminderFloatingAddButton`)
- Changes to list reorder, delete, rename flows
- Subtask or task-level creation (only list and group creation)

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Creation UX | Sheet with nav bar toolbar (Cancel / Create) | Alerts can't show pickers. Bottom buttons get covered by keyboard. Toolbar is always accessible. Standard iOS pattern. |
| Association picker style | SwiftUI `Menu` with inline list | Fits naturally in a sheet row. "None" selected by default — association is always optional. |
| On-the-fly creation | Separate mini-sheet presented on top of the main sheet | Avoids sheet-dismissal dance. Clean separation of concerns — mini-sheet is a single text field + Create/Done. |
| Sections always visible | Lists and Groups headers are always shown even when empty | A new user sees the structure and knows where to create. Consistent with iOS Files, Notes. The inline creation row is the empty state. |
| Inline row style | Dashed circle + text, matching the existing "Add Reminder" pattern in TimelineView | Consistent visual language. Full-width `.contentShape(Rectangle())` hit target. |
| Section header `+` | Small `plus` icon in primary color, same font size as header text | Discoverable without being loud. Balanced trailing edge with the header text on leading edge. |
| Group creation without source list | Empty group is created; lists can be added later via drag or context menu | No deadlock. User can create groups first, then populate them. |
| State management | ViewModel already has `isCreatingList`, `isCreatingGroup` booleans. The new sheet replaces the existing `.alert()` modifiers. | Existing ViewModel patterns are kept; alerts are replaced by sheet state but the underlying creation logic (`viewModel?.createList`, `viewModel?.createGroup`) stays. |

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Two sheets stacked (main + mini) could feel deep | Keep mini-sheet minimal — text field only + Create/Done. No association picker in the mini-sheet. Easy to cancel out. |
| User might not notice inline rows if the section has many items | The `+` header button serves as a persistent top-of-section CTA. Both affordances exist. |
| Section header `+` button has a small tap target (13pt) | Use `.contentShape(Rectangle())` on the button to expand the hit area to the full trailing side of the header row. |
| Remove the FAB entirely could confuse existing users who're used to it | The header `+` and inline row cover the same action. The alert that the FAB used to trigger is replaced by the richer sheet. Familiar Cancel/Create buttons. |
