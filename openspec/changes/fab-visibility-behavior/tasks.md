## 1. Add visibility state to views

- [ ] 1.1 Add computed `isFABHidden` to `ReminderSegmentDetailView` that checks `activeCaptureDate == nil`
- [ ] 1.2 Add computed `isFABHidden` to `ListDetailView` that checks `isQuickCapturing == false && editMode?.wrappedValue.isEditing == false`
- [ ] 1.3 Wrap each `ReminderFloatingAddButton` in `.overlay` with a conditional `if !isFABHidden`

## 2. Implement swipe detection (deferred)

- [ ] 2.1 Research UIScrollViewDelegate / UIViewRepresentable approach for detecting active swipe gestures
- [ ] 2.2 Implement swipe detection and integrate with isFABHidden state
- [ ] 2.3 Verify FAB hides during swipe and reappears after swipe dismiss

## 3. Verify and test

- [ ] 3.1 Run app and verify FAB hides/shows during quick capture in Today/Tomorrow/Upcoming
- [ ] 3.2 Run app and verify FAB hides/shows during quick capture in DetailView
- [ ] 3.3 Run app and verify FAB hides/shows during edit mode in DetailView
