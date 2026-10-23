# Spec Index

All behavioral specs for Wednesday Calendar (internal: TaskFlow), grouped by domain. The anchor doc for the product's two-domain model is [app-mental-model](app-mental-model/spec.md). Read it before changing navigation or organization.

## Anchor

| Spec | Covers |
|---|---|
| [app-mental-model](app-mental-model/spec.md) | Canonical model: exactly two domains (Work/Personal), lists inside domains, cross-domain Today |

## Navigation

| Spec | Covers |
|---|---|
| [tab-bar-navigation](tab-bar-navigation/spec.md) | Fixed Today/Work/Personal/More TabView, per-tab NavigationStacks, no project tabs |

## Tasks & attention

| Spec | Covers |
|---|---|
| [task-row-display](task-row-display/spec.md) | Row content, Deadline submenu, metadata, collapse affordances, hit targets |
| [task-subtasks](task-subtasks/spec.md) | Parent-child nesting, cascade rules, flat rendering in segments |
| [completion-interaction](completion-interaction/spec.md) | Completion haptic + deferred exit animation |
| [quick-capture](quick-capture/spec.md) | Context-aware FAB defaults for Today, domains, board columns, and list detail |
| [task-ordering](task-ordering/spec.md) | Daily drag reorder, custom-list drag reorder, Top/Bottom shortcuts |
| [overdue-view](overdue-view/spec.md) | Collapsible Overdue section inside the cross-domain Today tab |
| [completed-view](completed-view/spec.md) | Recently Completed under More, un-complete via swipe |
| [reminder-context-menu-delete](reminder-context-menu-delete/spec.md) | Delete action in row context menus |

## Lists (organization inside domains)

| Spec | Covers |
|---|---|
| [list-groups](list-groups/spec.md) | Domain model: exactly two fixed domains, lists as projects inside them |
| [list-management](list-management/spec.md) | List rename/delete cascades + list drag reorder |
| [inline-list-group-creation](inline-list-group-creation/spec.md) | List creation inside a domain; no user-created domains |
| [list-picker](list-picker/spec.md) | List assignment picker grouped by Work/Personal domain |

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
