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
- Every task — top-level or subtask — qualifies for a time tab solely by its own `dueDate`. Only subtasks that carry their own due date surface in time tabs, rendered as standalone flat rows alongside top-level tasks (no indentation, no expand/collapse).
- Subtasks without a due date are invisible in time tabs; they are visible only in their permanent home (list detail) and the editor.
- Parent rows indicate remaining subtask work via a completed/total fraction (e.g., "1/3") instead of inline trees.
- Nesting is capped at one level: a subtask can never have children. Legacy deeper hierarchies are flattened by detaching everything below depth 1 into independent top-level tasks (see `task-subtasks`).

### Navigation

The app has a **single 4-tab `TabView`** as its only navigation surface. There is no sidebar.

| Tab | Purpose | Content |
|---|---|---|---|
| Today | Attention now | Tasks due today (dated subtasks included, flat) |
| Tomorrow | Attention next | Tasks due tomorrow (dated subtasks included, flat) |
| Upcoming | Coming in future | Tasks due D+2 onward (dated subtasks included, flat) |
| Later | Permanent home | Groups (areas) and lists — the organizational structure |

### Later tab

- "Later" is **not** a someday bucket. It is the permanent organizational home of a user's tasks, lists, and projects, independent of due dates.
- Later's content: `ReminderListGroup` (grouped as expandable sections) and `ReminderList` items.
- The default list is called **"Inbox"** (not "Reminders"). It is a staging area for new/uncategorized tasks.
- Tapping a list pushes `ListDetailView` onto Later's `NavigationStack`.

### Dead code

The `ReminderSegment.later` case has been **removed**. It was unused — no view referenced it. The enum contains only `.today`, `.tomorrow`, `.upcoming`, `.overdue`.

The context menu exposes due-date actions inside a single "Deadline" submenu — **"None"** (always listed, no leading icon), a divider, then Today, Tomorrow, This Weekend, Next Week, Custom… (in `TaskRowView.swift`). Each preset row carries a leading calendar icon with its target day-of-month. The menu is state-aware via an active-item checkmark: "None" is ticked when the task has no date, the matching preset when the due date equals its target day, and Custom… for any other date; nothing is hidden. "None" clears a task's due date, causing it to disappear from time tabs and appear only in the Later tab — which is consistent with the mental model.
