# Spec Index

All behavioral specs for Wednesday Calendar (internal: TaskFlow), grouped by domain. The anchor doc for the product's two-axis model is [app-mental-model](app-mental-model/spec.md).

## Anchor

| Spec | Covers |
|---|---|
| [app-mental-model](app-mental-model/spec.md) | Two-axis model (attention vs home), navigation philosophy |

## Navigation

| Spec | Covers |
|---|---|
| [tab-bar-navigation](tab-bar-navigation/spec.md) | 4-tab root TabView, per-tab NavigationStacks, Later tab structure |

## Tasks (attention axis)

| Spec | Covers |
|---|---|
| [task-row-display](task-row-display/spec.md) | Row content, metadata, collapse affordances, hit targets |
| [task-subtasks](task-subtasks/spec.md) | Parent-child nesting, cascade rules, flat rendering in segments |
| [completion-interaction](completion-interaction/spec.md) | Completion haptic + deferred exit animation |
| [quick-capture](quick-capture/spec.md) | Context-aware FAB, inline capture rows, per-day Upcoming capture |
| [task-ordering](task-ordering/spec.md) | Daily drag reorder, custom-list drag reorder, Top/Bottom shortcuts |
| [overdue-view](overdue-view/spec.md) | Overdue sidebar filter + collapsed section in Today |
| [completed-view](completed-view/spec.md) | Completed smart filter, un-complete via swipe |
| [reminder-context-menu-delete](reminder-context-menu-delete/spec.md) | Delete action in row context menus |

## Lists (home axis)

| Spec | Covers |
|---|---|
| [list-groups](list-groups/spec.md) | Group data model, expandable sections, drag between groups |
| [list-management](list-management/spec.md) | List rename/delete cascades + list drag reorder |
| [inline-list-group-creation](inline-list-group-creation/spec.md) | Creation sheets and mini-sheet flows |
| [list-picker](list-picker/spec.md) | List assignment picker in editor |

## Editor

| Spec | Covers |
|---|---|
| [reminder-authoring](reminder-authoring/spec.md) | Rich fields, save validation, discard protection |
| [reminder-scheduling](reminder-scheduling/spec.md) | hasTime persistence, date/time toggles and pickers |

## Notifications

| Spec | Covers |
|---|---|
| [task-notifications](task-notifications/spec.md) | Full notification lifecycle incl. activation cleanup + upgrade migration |
| [task-count-badge](task-count-badge/spec.md) | App icon badge from overdue+today counts |

## Bulk operations

| Spec | Covers |
|---|---|
| [bulk-editing](bulk-editing/spec.md) | Selection mode UX + toolbar bulk actions |

## Data & compatibility

| Spec | Covers |
|---|---|
| [reminder-persistence-compatibility](reminder-persistence-compatibility/spec.md) | Non-destructive schema migration policy |

---

## Maintenance rules

1. **Amend, don't proliferate.** New behavior lands in an existing capability spec unless it's genuinely a new capability. A new requirement ≠ a new folder.
2. **Prune on cadence.** Each release: delete specs for removed behavior, flag overlapping requirements for merging.
3. **Format:** every spec has `## Purpose` + flat `## Requirements` + `#### Scenario:` blocks. No stale `ADDED/MODIFIED` delta markers in main specs.
4. Consolidated 2026-08 from 33 → 20 specs; superseded micro-specs live on only in `openspec/changes/archive/` history.
