## Context

The task editor (`ReminderEditorView`) currently exposes title, notes, URL, date/time, and subtasks — but not list assignment. The data layer already supports it: `ReminderDraft.listName` stores the list name, and `ReminderDraftMapper.apply()` resolves it to a `ReminderList` on save. The only gap is UI.

The existing "Move to List" context menu on task rows uses a `Menu` with `buildListSections()` to group lists. This works for few lists but doesn't scale. We need a dedicated full-screen picker with search.

## Goals / Non-Goals

**Goals:**
- Show current list assignment in the editor form
- Allow changing list via a full-screen searchable picker
- Reuse `buildListSections()` for grouped display
- Pre-select list based on entry context (list view → that list, tabs → Inbox)
- Work for both new task creation and editing existing tasks

**Non-Goals:**
- Changing list assignment from task rows (already works via context menu)
- Batch list reassignment
- Moving subtasks when parent list changes (existing behavior clears `parentTask`)
- Schema migration (no model changes needed)

## Decisions

### 1. Full-screen picker (always navigate)

**Decision**: Always navigate to a dedicated `ListPickerView`, regardless of list count.

**Why**: A `Menu` dropdown works for ≤5 lists but becomes unusable at 20+. A full-screen picker with search scales to any count. For small lists, the picker is just a short list — still fast. Consistency (one pattern) beats optimization (two paths).

**Alternative considered**: Adaptive approach (inline picker for few lists, full-screen for many). Rejected — two code paths, arbitrary threshold, maintenance overhead.

### 2. Reuse `buildListSections` for grouping

**Decision**: The picker uses the same `buildListSections()` function that powers the Lists tab and context menus.

**Why**: Consistent grouping across the app. Lists appear in the same order with the same section headers users already know. No duplicated grouping logic.

### 3. Search bar always visible

**Decision**: Show the search bar regardless of list count.

**Why**: Even with few lists, search is a compact UI element (one line). Removing it conditionally adds complexity for minimal gain. Users who know what they're looking for get a fast path.

### 4. List selection updates draft, not task directly

**Decision**: The picker updates `draft.listName` (a string). The actual `ReminderList` resolution happens in `ReminderDraftMapper.apply()` on save.

**Why**: Keeps the editor flow consistent — the draft is the single source of truth during editing. Avoids side effects before save.

### 5. Subtasks stay in old list when parent list changes

**Decision**: When a user changes a parent task's list in the editor, existing subtasks are NOT moved. Only the parent's `reminderList` changes on save.

**Why**: Matches existing behavior in `DetailViewModel.moveTask()` which clears `parentTask` when moving. Subtask cross-list movement is a separate concern.

## Risks / Trade-offs

- [Extra tap for small lists] → Acceptable trade-off for consistency. The picker for 3 lists is 3 tappable rows — sub-second interaction.
- [Search across grouped lists] → Search must filter across all groups, not within a group. The flat filtered results should still show group headers for context.
- [Draft listName vs list ID] → Using name (string) means renaming a list after creating a draft could cause a mismatch. This is pre-existing behavior in `ReminderDraftMapper` and is acceptable — the mapper creates a new list if the name doesn't match.
