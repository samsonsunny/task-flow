## 1. Fix openQuickCaptureEditor in TimelineView

- [ ] 1.1 Add `skipNextDismiss = true` at the top of `openQuickCaptureEditor()` in `TimelineView.swift:576`
- [ ] 1.2 Move `newReminderConfig` assignment after `activeCaptureDate = nil` inside a `Task { @MainActor in }` block

## 2. Fix openQuickCaptureEditor in DetailView

- [ ] 2.1 Add `skipNextDismiss = true` at the top of `openQuickCaptureEditor()` in `DetailView.swift`
- [ ] 2.2 Move `newReminderConfig` assignment after `activeCaptureDate = nil` inside a `Task { @MainActor in }` block

## 3. Verify

- [ ] 3.1 Build with `xcodebuild`
- [ ] 3.2 Run UI test `testQuickCaptureChevronOpensEditor`
