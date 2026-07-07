## Context

The "Move to List" context menu action currently renders all lists as a flat `ForEach(availableLists)` with no grouping or sectioning. The data model already supports `ReminderListGroup` with a `group` relationship on `ReminderList`, but this structure is not reflected in the context menu.

Two ViewModels expose lists for this menu:
- `TimelineViewModel.otherLists` — returns all lists (flat)
- `ListDetailViewModel.otherLists` — returns all lists except current

Both are consumed by `TaskRowView` via `availableLists: [ReminderList]`.

## Goals / Non-Goals

**Goals:**
- Organize lists into sections by group in the "Move to List" submenu
- Pin the default list (Inbox) at top in its own section
- Keep grouped lists under group name headers, ungrouped at bottom
- Backward compatible: no groups = flat list (identical to today)
- Unit test coverage for the section-building logic

**Non-Goals:**
- No data model changes (no new relationships, no schema migration)
- No changes to the ListView context menu (already group-aware)
- No search/filter inside the menu (future improvement)
- No UI redesign beyond section separators

## Decisions

### Decision: Introduce `ListSection` value type

A simple struct shared between ViewModels to represent a menu section:

```swift
struct ListSection: Identifiable {
    let id: String
    let title: String?
    let lists: [ReminderList]
}
```

**Why not a tuple or inline dictionary?** The type needs `Identifiable` for `ForEach` in the view, and having a named type makes unit testing straightforward.

**Why not put this in the view?** The grouping logic is business logic (which lists go where) — belongs in the ViewModel per MVVM conventions.

### Decision: Replace `otherLists` with `listSections` on ViewModels

Each ViewModel replaces its `otherLists` computed property with `listSections` returning `[ListSection]`.

Construction logic (shared helper or inline):
1. Collect all lists, exclude current list
2. Separate default list (Inbox) if present → section with no title
3. Group remaining lists by `ReminderListGroup` → section per group with group name as title
4. Remaining ungrouped lists → section with no title
5. Order: default → grouped (by group sort order) → ungrouped (by list sort order)

**Why not a shared utility?** The logic is simple enough to keep in each ViewModel. If a third consumer emerges, extract. Follow YAGNI.

### Decision: `TaskRowView` uses `Section` inside `Menu`

Change from:
```swift
Menu("Move to List") {
    ForEach(availableLists) { list in ... }
}
```

To:
```swift
Menu("Move to List") {
    ForEach(listSections) { section in
        Section(section.title ?? "") {
            ForEach(section.lists) { list in ... }
        }
    }
}
```

When `title` is an empty string, SwiftUI `Section` renders only the separator line (no text header), which is exactly the desired visual.

**Why not `Menu` with submenus per group?** D (the chosen approach) uses `Section` for visual grouping without adding a tap-through submenu level. This keeps the action fast: two taps to move a task (Move to List → List name), not three (Move to List → Group → List name).

### Decision: `availableLists` property renamed to `listSections` on `TaskRowView`

The `TaskRowView` property changes from `availableLists: [ReminderList]` to `listSections: [ListSection]`. The `availableLists` name is no longer accurate.

## Risks / Trade-offs

- **[Section visibility]** When `title` is empty string, SwiftUI `Section` still renders a thin separator line. With one section this is unnoticeable. With the default-list section + ungrouped section, there's a thin line between them. Acceptable — matches iOS Settings.app style.
- **[Performance]** Negligible. List counts are typically < 50. The grouping is O(n).
- **[Existing tests]** `DraftTests.swift` passes `availableLists` to `Draft`. This will need updating to the new type.
