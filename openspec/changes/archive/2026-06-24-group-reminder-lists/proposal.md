## Why

Users need to organize their reminder lists into groups (like Apple Reminders Groups) to manage multiple lists across contexts like Work, Personal, or Projects. Currently all lists are flat, which becomes unwieldy as the number of lists grows.

## What Changes

- Introduce `ReminderListGroup` model with a 1:N relationship to `ReminderList`
- ListsTabView: groups displayed as expandable/collapsible sections with list rows nested inside
- Context menu on list rows: "Create New Group" flow, "Move to Group →" menu
- Drag-and-drop reorder for groups, lists within groups, and ungrouped lists
- Default "Reminders" list pinned at top, outside any group
- Schema migration (lightweight, additive — no data loss)

## Capabilities

### New Capabilities
- `list-groups`: Reminder list grouping — data model, group display with expand/collapse, context menu group creation, move-to-group, drag-and-drop reorder of groups and lists, migration

### Modified Capabilities

<!-- No existing specs are changing; this is an entirely new capability -->

## Impact

- **Models**: New `ReminderListGroup` SwiftData model; `ReminderList.group` optional inverse relationship
- **Views**: `ListsTabView.swift` rewritten to support group sections, expand/collapse, pinned default list
- **Features**: Context menu extension, drag-drop reorder for groups and lists
- **Migration**: Lightweight schema migration with zero data loss; existing lists are ungrouped by default
