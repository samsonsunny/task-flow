## Context

`ListsTabView` (436 lines) manages all list and group CRUD operations. It has 6 alert dialogs (create list, create group, rename list, rename group, delete list, delete group), context menus with move-to-group submenus, drag-drop reorder with midpoint algorithm, and group expand/collapse persisted to `UserDefaults`. Every alert has its own `@State` flags and text fields, interleaving UI presentation with data mutations.

The existing `midpoint`/`widen` algorithm for reorder is already unit tested in `SortOrderMidpoint.swift`.

## Goals / Non-Goals

**Goals:**
- Extract `ListsTabViewModel` as an `@Observable` class owning all list/group CRUD logic, dialog state, and reorder logic
- VM owns: all alert presentation state (booleans and selected items), text field values, list/group creation mutation, rename mutation, delete cascade, reorder, group assignment, expand/collapse persistence
- View retains: `@Query` for data, rendering structure (sections, navigation links), context menu structure
- All mutations become VM methods called from the view

**Non-Goals:**
- Changing list/group model interfaces or sort order algorithm
- Altering the UI layout of list rows, sections, or navigation
- Changing the delete cascade behavior (two-option confirmation)
- Adding new list/group features

## Decisions

### 1. VM owns all dialog presentation state

```swift
@Observable
final class ListsTabViewModel {
    // Dialog visibility
    var isCreatingList = false
    var newListName = ""

    var isRenamePresented = false
    var renameList: ReminderList?
    var renameText = ""

    var deleteList: ReminderList?

    var isCreatingGroup = false
    var newGroupName = ""
    var groupSourceList: ReminderList?

    // ...
}
```

**Rationale:** Every alert's `@State` in the current view maps directly to a VM property. The view binds to VM properties and calls VM methods on button taps.

### 2. Group expand/collapse managed by VM

The VM persists group expansion state to `UserDefaults` and provides a `Binding<Bool>`-compatible interface for `DisclosureGroup`.

```swift
func isGroupExpanded(_ group: ReminderListGroup) -> Bool
func toggleGroupExpanded(_ group: ReminderListGroup)
```

### 3. Reorder stays as a VM method

```swift
func moveLists(fromOffsets: IndexSet, toOffset: Int, in source: [ReminderList], group: ReminderListGroup? = nil)
```

Same midpoint/widen logic, moved from view private method to VM method.

### 4. Derived properties in VM

```swift
var defaultList: ReminderList? { ... }
var ungroupedLists: [ReminderList] { ... }
```

Computed from the lists array, same as current view.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| **Many dialog states**: 6+ boolean/optionals to coordinate | The VM centralizes all of them. Currently they're scattered `@State` vars — the VM is actually an improvement in organization. |
| **Context menu structure stays in view**: Some logic still in view for conditional menu items | Acceptable. Context menus are view structure, not business logic. The VM provides methods like `canDeleteList(_:)` that the view calls to decide menu visibility. |
| **Lists/arrays passed on every update**: View passes `lists`, `groups`, `allTasks` to VM | Same pattern as other ViewModels. Pure computation, negligible cost. |
