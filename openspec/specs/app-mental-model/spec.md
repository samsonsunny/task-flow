## Mental Model

### Two axes

The app has two orthogonal axes of navigation:

```
ATTENTION AXIS (time-based tabs)       HOME AXIS (Later tab)
─────────────────────────────────      ─────────────────────

[Today] [Tomorrow] [Upcoming]          [Later]
tasks are surfaced based on           tasks live here
their due date                        permanently, organized
                                      into groups and lists

┌──────┐ ┌────────┐ ┌──────────┐      ┌──────────────────┐
│Today │ │Tomorrow│ │Upcoming  │      │ Group: Work      │
│      │ │        │ │          │      │ ├── List: Proj A │
│ tasks│ │ tasks  │ │ tasks    │      │ ├── List: Proj B │
│ due  │ │ due    │ │ due      │      │ └── tasks…      │
│today │ │tomorrow│ │ D+2→+∞   │      └──────────────────┘
└──────┘ └────────┘ └──────────┘
```

**A task lives in both axes simultaneously:**
- It belongs to a list in Later (its permanent home)
- If it has a due date, it surfaces in a time tab (its attention signal)
- Removing the due date ("Move to Later" context action) returns it to Later-only visibility

**Subtasks in time tabs:**
- When a task passes a time tab's filter by its own `dueDate`, ALL its descendants render inline beneath it — regardless of the subtask's own due date (inherited date context). Subtasks without a `dueDate` become visible through their ancestor's filter match.
- When a subtask independently passes a time tab's filter but its parent does not, it appears standalone at depth 0 (no parent context pulled in).
- Each parent is expandable/collapsible. Collapse state is per-view (independent between time tabs and list detail).
- Within a single view, a subtask rendered under its parent is not duplicated as a standalone row (dedup).

### Navigation

The app has a **single 4-tab `TabView`** as its only navigation surface. There is no sidebar.

| Tab | Purpose | Content |
|---|---|---|---|
| Today | Attention now | Tasks due today + their subtasks inline (expandable/collapsible) |
| Tomorrow | Attention next | Tasks due tomorrow + their subtasks inline (expandable/collapsible) |
| Upcoming | Coming in future | Tasks due D+2 onward + their subtasks inline (expandable/collapsible) |
| Later | Permanent home | Groups (areas) and lists — the organizational structure |

### Later tab

- "Later" is **not** a someday bucket. It is the permanent organizational home of a user's tasks, lists, and projects, independent of due dates.
- Later's content: `ReminderListGroup` (grouped as expandable sections) and `ReminderList` items.
- The default list is called **"Inbox"** (not "Reminders"). It is a staging area for new/uncategorized tasks.
- Tapping a list pushes `ListDetailView` onto Later's `NavigationStack`.

### Dead code

The `ReminderSegment.later` case has been **removed**. It was unused — no view referenced it. The enum contains only `.today`, `.tomorrow`, `.upcoming`, `.overdue`.

The context menu exposes due-date actions inside a single "Deadline" submenu — **"None"** (always listed, no leading icon), a divider, then Today, Tomorrow, This Weekend, Next Week, Custom… (in `TaskRowView.swift`). Each preset row carries a leading calendar icon with its target day-of-month. The menu is state-aware via an active-item checkmark: "None" is ticked when the task has no date, the matching preset when the due date equals its target day, and Custom… for any other date; nothing is hidden. "None" clears a task's due date, causing it to disappear from time tabs and appear only in the Later tab — which is consistent with the mental model.
