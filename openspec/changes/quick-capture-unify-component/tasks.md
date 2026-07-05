## 1. Update QuickCaptureRow component

- [x] 1.1 Replace `@FocusState.Binding var isFocused: Bool` with internal `@FocusState private var isFocused`
- [x] 1.2 Replace `let onSubmit: () -> Void` with `let onSubmit: (String) -> Void`
- [x] 1.3 Add `let onDismiss: () -> Void` callback parameter
- [x] 1.4 Remove `let dateHint: String?` parameter and the date hint VStack/label
- [x] 1.5 Remove `import Combine`
- [x] 1.6 Add internal `onChange(of: isFocused)` handler: on focus-loss, commit text if non-empty via `onSubmit`, clear text, call `onDismiss`
- [x] 1.7 Add internal `handleSubmit` method: trim text, guard non-empty, clear text, re-focus, call `onSubmit(text)`

## 2. Clean up ListDetailView

- [x] 2.1 Remove `@FocusState private var isQuickCaptureFocused: Bool`
- [x] 2.2 Remove `@State private var skipNextDismiss = false`
- [x] 2.3 Remove entire `onChange(of: isQuickCaptureFocused)` block
- [x] 2.4 Remove `private func commitQuickCapture()` method
- [x] 2.5 Update QuickCaptureRow call: remove `isFocused:`, `dateHint:`, replace `onSubmit: commitQuickCapture` with `onSubmit: { viewModel?.commitQuickCapture(text: $0, in: listID) }`, add `onDismiss: { isQuickCapturing = false }`

## 3. Clean up TimelineView

- [x] 3.1 Remove `@FocusState private var isQuickCaptureFocused: Bool`
- [x] 3.2 Remove `@State private var skipNextDismiss = false`
- [x] 3.3 Remove entire `onChange(of: isQuickCaptureFocused)` block
- [x] 3.4 Remove `private func commitQuickCapture()` method
- [x] 3.5 Remove `private func commitQuickCaptureWithDate(_ date: Date)` method
- [x] 3.6 Update QuickCaptureRow calls in `todayLikeContent`: remove `isFocused:`, `dateHint:`, replace `onSubmit: commitQuickCapture` with `onSubmit: { viewModel?.commitQuickCapture(text: $0, captureDate: activeCaptureDate) }`, add `onDismiss: { activeCaptureDate = nil }`
- [x] 3.7 Update QuickCaptureRow calls in `upcomingContent`/`emptyDayRow`/`emptyMonthRow`/`monthSectionView`: remove `isFocused:`, `dateHint:`, replace `onSubmit: { commitQuickCaptureWithDate(date) }` with `onSubmit: { viewModel?.commitQuickCapture(text: $0, captureDate: date) }`, add `onDismiss: { activeCaptureDate = nil }`

## 4. Verify

- [x] 4.1 Build — exit code 0, no compilation errors
- [ ] 4.2 Manual: List Detail + tap → field appears, commit creates task, tap-away dismisses
- [ ] 4.3 Manual: Today/Tomorrow + tap → same behavior, field scrolls into view
- [ ] 4.4 Manual: Upcoming per-day field → commit creates task with correct date
- [ ] 4.5 Manual: Tap away from field → dismisses, text committed
