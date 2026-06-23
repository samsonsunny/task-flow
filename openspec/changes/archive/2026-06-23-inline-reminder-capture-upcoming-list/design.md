## Context

The Upcoming view (`ReminderSegmentDetailView`) currently has multiple CTAs that all open the full `ReminderEditorView` sheet:
- Per-day "Add Reminder" buttons (dashed circle)
- Tappable day section headers
- Tappable empty day rows
- Tappable month headers and day sub-section activators

A floating `+` button exists but opens the sheet too (no inline capture).

The global `isQuickCapturing: Bool` + `quickCaptureText` state drives a single top-of-list inline field in Today/Tomorrow/Later/Overdue segments.

ListDetailView has no inline capture at all — `+` opens the sheet directly.

## Goals / Non-Goals

**Goals:**
- Upcoming: All CTAs activate a per-day inline text field instead of opening the editor
- Upcoming: Single active inline field at a time across all sections
- Upcoming: Committing the inline field creates a task with that day's date
- ListDetailView: `+` triggers inline quick capture at the top of the list
- ListDetailView: Committed tasks get the current list, no date
- Both: Chevron button on the inline field opens the full editor with contextual defaults pre-filled

**Non-Goals:**
- Changing the floating `+` behavior in Upcoming (remains sheet-only, no default date)
- Changing Today/Tomorrow/Later/Overdue inline capture behavior
- Batch field interaction (multiple fields open simultaneously)
- Drag-to-reorder within the inline field

## Decisions

### Decision 1: `activeCaptureDate` replaces `isQuickCapturing` in Upcoming

**Approach:** Replace `@State private var isQuickCapturing = false` with `@State private var activeCaptureDate: Date?`. The field renders when `activeCaptureDate != nil`. Setting it to a new date replaces the prior one. Setting it to `nil` closes the field.

**Why:** A Bool can't encode which day section the field belongs to. A Date? naturally carries that context, while a nil/non-nil check serves as the show/hide flag.

**Why not separate states:** Having `isQuickCapturing` AND `activeDate` creates an invalid state (capturing without a date). A single optional enforces the invariant.

**Commit behavior:**
```swift
private func commitQuickCapture() {
    guard let date = activeCaptureDate else { return }
    let text = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    let task = TaskItem(taskTitle: text, dueDate: date)
    task.reminderList = resolvedQuickCaptureList()
    modelContext.insert(task)
    quickCaptureText = ""
    // field stays open, focused for rapid entry
}
```

### Decision 2: All existing CTAs set `activeCaptureDate` instead of opening sheet

Each CTA currently does `newReminderConfig = NewReminderConfig(initialDate: date, ...)`. Instead, they set `activeCaptureDate = date` and `isQuickCaptureFocused = true`.

| CTA | Before | After |
|---|---|---|
| `addReminderButton(date:)` | Sets `newReminderConfig` | Sets `activeCaptureDate = date` |
| `dayHeader` tap | Sets `newReminderConfig` | Sets `activeCaptureDate = date` |
| `emptyDayRow` tap | Sets `newReminderConfig` | Sets `activeCaptureDate = date` |
| `monthSectionView` day tap | Sets `newReminderConfig` | Sets `activeCaptureDate = date` |
| Floating `+` | Sets `isQuickCapturing = true` | No change (remains sheet-only) |

### Decision 3: Inline field renders conditionally per section

The inline field is rendered inside each day/month section when that section's date matches `activeCaptureDate`:

```swift
if activeCaptureDate == date {
    quickCaptureRow
}
```

Only one section renders the field at a time. The quick capture row is the same view as Today/Tomorrow uses, but shows a date hint label (e.g., "→ Thu, Jun 25") to indicate where the task will land.

The existing top-of-list `if isQuickCapturing { quickCaptureRow }` in the body is removed for the `.upcoming` segment.

### Decision 4: ListDetailView uses the same `isQuickCapturing` pattern as Today/Tomorrow

ListDetailView gets the same three states: `isQuickCapturing`, `quickCaptureText`, `isQuickCaptureFocused`. The floating `+` button sets `isQuickCapturing = true`. Commit uses `resolvedQuickCaptureList()` (the current list) and `dueDate: nil`.

**Why only ListDetailView uses the Bool pattern:** There are no date sections in a list view, so there's no need for a Date?-based state. The single field at the top of the list maps cleanly to the Bool pattern.

### Decision 5: Chevron opens full editor with contextual defaults

In Upcoming: opens `ReminderEditorView` with `initialDate = activeCaptureDate`.
In ListDetailView: opens `ReminderEditorView` with `initialListID = listID`, `initialDate = nil`.

The field closes when the sheet opens.

## Risks / Trade-offs

- **Empty day rows currently show a tappable thin text header** → These will now open the inline field. The hit target may feel small compared to the dashed-circle button. Consider making the entire empty day row tappable, or adding a dashed circle to empty days for visual consistency.
- **Month sub-sections already have indented inline items** → The inline field inside a month sub-section will appear at that indented level, which may feel cramped. Verify spacing works with the existing padding.
- **Existing "Add Reminder" button text becomes redundant** → Once the inline field is active, the button disappears (replaced by the field). If the field is closed, the button reappears. This matches the Today view's pattern of show/hide.
