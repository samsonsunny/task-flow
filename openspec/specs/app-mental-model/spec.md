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

**Subtasks in time tabs (under exploration):**
- All descendants of a root task that passes the time filter are shown inline with their parent, regardless of the subtask's own due date
- A subtask with its own due date that matches a time tab but whose parent does not appears standalone at depth 0
- The exact nesting approach (inline expansion vs count link) is pending further research — see `changes/subtasks-in-time-tabs/`

### Navigation

The app has a **single 4-tab `TabView`** as its only navigation surface. There is no sidebar.

| Tab | Purpose | Content |
|---|---|---|---|
| Today | Attention now | Tasks due today + their subtasks (flat or nested — TBD) |
| Tomorrow | Attention next | Tasks due tomorrow + their subtasks (flat or nested — TBD) |
| Upcoming | Coming in future | Tasks due D+2 onward + their subtasks (flat or nested — TBD) |
| Later | Permanent home | Groups (areas) and lists — the organizational structure |

### Later tab

- "Later" is **not** a someday bucket. It is the permanent organizational home of a user's tasks, lists, and projects, independent of due dates.
- Later's content: `ReminderListGroup` (grouped as expandable sections) and `ReminderList` items.
- The default list is called **"Inbox"** (not "Reminders"). It is a staging area for new/uncategorized tasks.
- Tapping a list pushes `ListDetailView` onto Later's `NavigationStack`.

### Dead code

The `ReminderSegment.later` case has been **removed**. It was unused — no view referenced it. The enum contains only `.today`, `.tomorrow`, `.upcoming`, `.overdue`.

The context menu action label `"Later"` (hardcoded in `TaskRowView.swift:46`) is preserved. It clears a task's due date, causing it to disappear from time tabs and appear only in the Later tab — which is consistent with the mental model.
