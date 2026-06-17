## 1. TaskRowView — Add delete support

- [x] 1.1 Add `var onDelete: (() -> Void)? = nil` parameter to `TaskRowView`
- [x] 1.2 Add Delete button with `.role(.destructive)` to `.contextMenu`, gated on `onDelete`

## 2. Wire delete in ReminderSegmentDetailView

- [x] 2.1 Pass `onDelete: { modelContext.delete(task) }` to `TaskRowView` in `taskListRow`

## 3. Wire delete in ListDetailView

- [x] 3.1 Pass `onDelete: { modelContext.delete(task) }` to `TaskRowView` in `taskListRow`
