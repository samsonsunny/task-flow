## 1. Draft Model Changes

- [x] 1.1 Add `hasTime: Bool` property to `ReminderDraft` struct with proper initialization:
  - `empty`: `hasTime = false`
  - `init(title:notes:...)`: `hasTime = false` by default
  - `init(task:)`: `hasTime = true` only when `dueDate` has non-midnight time
  - When `initialDate` is passed to `ReminderEditorView`: `hasTime = false` (date pre-filled, time opt-in)
- [x] 1.2 Update `ReminderDraft.hasMeaningfulContent` — `hasTime` alone should not count as meaningful content (time without date is meaningless)
- [x] 1.3 Update `ReminderDraft` equality — `hasTime` should be part of the Equatable comparison

## 2. Mapper Changes

- [x] 2.1 Update `ReminderDraftMapper.apply` to conditionally normalize `dueDate`: when `hasTime` is true, preserve the full date with time; when false, continue using `startOfDay`
- [x] 2.2 Ensure `hasTime` derivation on edit — when initializing `ReminderDraft(task:)`, check if `dueDate` has non-midnight time components and set `hasTime` accordingly

## 3. Schedule Section Rewrite

- [x] 3.1 Replace current toggle + compact DatePicker with a new schedule section layout containing date row and time row
- [x] 3.2 Implement date row: Toggle, subtitle showing formatted date when on, tap to expand/collapse inline `DatePicker` with `.date` components
- [x] 3.3 Implement time row: Toggle (disabled when date is off), subtitle showing formatted time when on, tap to expand/collapse inline `DatePicker` with `.hourAndMinute` components
- [x] 3.4 Implement nearest rounded hour logic: when time toggle is first enabled, default to nearest future 30-minute boundary
- [x] 3.5 Implement date toggle off → auto-remove time: when date toggle is turned off, set `hasTime = false` and reset the time component
- [x] 3.6 Use a single `@State` optional enum (`ExpandedPicker?`) for mutually exclusive expand/collapse — opening one picker auto-collapses the other; collapse on selection by setting to nil

## 4. Verification

- [x] 4.1 Verify build succeeds with no errors or warnings
- [x] 4.2 Verify existing tests still pass (date-only behavior must be preserved)
