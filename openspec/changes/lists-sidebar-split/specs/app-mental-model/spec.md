## MODIFIED Requirements

### Two axes

The app has two orthogonal axes of navigation, shown in a split view:

```
ATTENTION AXIS (time home, detail column)   HOME AXIS (Lists, sidebar column)
───────────────────────────────────────    ───────────────────────────────

  [Today][Tomorrow][Upcoming]               │ Group: Work      │
  tasks are surfaced based on               │ ├── List: Proj A │
  their due date                            │ ├── List: Proj B │
                                            │ └── tasks…      │
```

**A task lives in both axes simultaneously:**
- It belongs to a list in Lists (its permanent home)
- If it has a due date, it surfaces in a time segment (its attention signal)
- Removing the due date ("Move to Later" context action) returns it to Lists-only visibility

**Subtasks in time segments:**
- Every task — top-level or subtask — qualifies for a time segment solely by its own `dueDate`. Only subtasks that carry their own due date surface in time segments, rendered as standalone flat rows alongside top-level tasks (no indentation, no expand/collapse).
- Subtasks without a due date are invisible in time segments; they are visible only in their permanent home (list detail) and the editor.
- Parent rows indicate remaining subtask work via a completed/total fraction (e.g., "1/3") instead of inline trees.
- Nesting is capped at one level: a subtask can never have children. Legacy deeper hierarchies are flattened by detaching everything below depth 1 into independent top-level tasks (see `task-subtasks`).

### Navigation

The app SHALL use a **`NavigationSplitView`** as its root navigation surface. The **sidebar column** is the Lists surface (the "where" axis); the **detail column** is the time home with a three-segment control (Today, Tomorrow, Upcoming — the "when" axis). There is no bottom tab bar.

| Surface | Purpose | Content |
|---|---|---|
| Sidebar: Lists | Permanent home | Groups (areas) and lists — the organizational structure |
|---|---|---|
| Detail: Today | Attention now | Tasks due today (dated subtasks included, flat) |
| Detail: Tomorrow | Attention next | Tasks due tomorrow (dated subtasks included, flat) |
| Detail: Upcoming | Coming in future | Tasks due D+2 onward (dated subtasks included, flat) |

Selecting a list in the sidebar SHALL show that list's tasks as the detail column content. With no list selected, the detail column shows the time home.

The capture bar SHALL be present on the time home and inside list detail, and SHALL be absent from the Lists overview.

### Later tab

"Later" is **not** a someday bucket, and is no longer a tab. The organizational home is the Lists sidebar column. Lists live independently of due dates.

- Lists content: `ReminderListGroup` (grouped as expandable sections) and `ReminderList` items, in the sidebar.
- The default list is called **"Inbox"** (not "Reminders"). It is a staging area for new/uncategorized tasks.
- Selecting a list shows its tasks in the detail column.

### Dead code

The `ReminderSegment.later` case has been **removed**. It was unused — no view referenced it. The enum contains only `.today`, `.tomorrow`, `.upcoming`, `.overdue`.

The context menu exposes due-date actions inside a single "Deadline" submenu — **"None"** (always listed, no leading icon), a divider, then Today, Tomorrow, This Weekend, Next Week, Custom… (in `TaskRowView.swift`). Each preset row carries a leading calendar icon with its target day-of-month. The menu is state-aware via an active-item checkmark: "None" is ticked when the task has no date, the matching preset when the due date equals its target day, and Custom… for any other date; nothing is hidden. "None" clears a task's due date, causing it to disappear from time segments and appear only in the Lists surface — which is consistent with the mental model.