## ADDED Requirements

### Requirement: FAB hides during quick capture

The FAB SHALL be hidden when a quick capture row is active in the view.

In `ReminderSegmentDetailView`, quick capture is active when `activeCaptureDate != nil`. In `ListDetailView`, quick capture is active when `isQuickCapturing == true`.

The FAB SHALL reappear when the quick capture row is dismissed (on submit or keyboard resign).

#### Scenario: FAB hides when quick capture appears
- **WHEN** user taps the FAB in Today/Tomorrow/Upcoming view
- **THEN** `activeCaptureDate` is set, a `QuickCaptureRow` appears with keyboard, AND the FAB is hidden

#### Scenario: FAB reappears after quick capture submit
- **WHEN** user submits a task via quick capture
- **THEN** the `QuickCaptureRow` dismisses, `activeCaptureDate` is cleared, AND the FAB reappears

#### Scenario: FAB reappears after quick capture cancel
- **WHEN** user taps outside the quick capture field to dismiss it
- **THEN** `onChange(of: isFocused)` fires, `onDismiss` is called, `activeCaptureDate` is cleared, AND the FAB reappears

#### Scenario: FAB hides in DetailView during quick capture
- **WHEN** user taps the FAB in `ListDetailView`
- **THEN** `isQuickCapturing` is set to true, a `QuickCaptureRow` appears, AND the FAB is hidden

### Requirement: FAB hides during edit mode

The FAB SHALL be hidden when `ListDetailView` is in edit mode (`editMode.wrappedValue.isEditing == true`).

The FAB SHALL reappear when edit mode is exited.

#### Scenario: FAB hides when entering edit mode
- **WHEN** user taps Edit or begins reordering tasks in `ListDetailView`
- **THEN** `editMode.isEditing` becomes true AND the FAB is hidden

#### Scenario: FAB reappears when exiting edit mode
- **WHEN** user taps Done or programmatically exits edit mode
- **THEN** `editMode.isEditing` becomes false AND the FAB reappears

### Requirement: FAB hides during swipe actions

The FAB SHALL be hidden while the user is swiping a list row to reveal trailing swipe actions (e.g., Delete).

The FAB SHALL reappear when the swipe gesture ends and actions are dismissed.

Detection MAY use `UIScrollViewDelegate` to observe scroll view dragging state, with intersection checks for the bottommost row's swipe area.

#### Scenario: FAB hides during row swipe
- **WHEN** user performs a trailing swipe gesture on any list row in a view containing the FAB
- **THEN** the swipe actions are revealed AND the FAB is hidden

#### Scenario: FAB reappears after swipe dismiss
- **WHEN** user taps elsewhere or the swipe actions auto-dismiss
- **THEN** the swipe gesture ends AND the FAB reappears

### Requirement: FAB is visible by default

The FAB SHALL be visible whenever none of the hiding conditions are active: no quick capture, no edit mode, no active swipe gesture.

This is the baseline state for all views that use the FAB.

#### Scenario: FAB visible on app launch
- **WHEN** user opens the app and lands on any tab
- **THEN** the FAB is visible in Today/Tomorrow/Upcoming/Later tabs and list detail views
