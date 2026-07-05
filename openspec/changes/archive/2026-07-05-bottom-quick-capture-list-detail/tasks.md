## 1. Revert the bad pinned-bar change in DetailView.swift

- [x] 1.1 Restore `DetailView.swift` to the original structure: `ScrollViewReader { proxy in List { ... } }` without the outer `VStack`; remove `.layoutPriority(1)`; remove the pinned `quickCaptureBar` outside the List
- [x] 1.2 Restore the original FAB action (no `proxy.scrollTo` call — will be added back in step 4)
- [x] 1.3 Restore the original `onChange(of: isQuickCapturing)` that scrolled to top (will be reworked in step 4)

## 2. Create shared QuickCaptureRow component

- [x] 2.1 Create `TaskFlow/Views/Components/QuickCaptureRow.swift` with the self-contained component owning `@Binding text`, `@FocusState.Binding isFocused`, `onSubmit` callback, and `dateHint`
- [x] 2.2 Support the `dateHint` overlay label ("→ Today", "→ Tomorrow") seen in Today/Tomorrow views
- [x] 2.3 Ensure it has `.id("quick-capture")` for scroll anchoring and `.transition(.move(edge: .bottom).combined(with: .opacity))`

## 3. Wire QuickCaptureRow into ListDetailView

- [x] 3.1 Remove the existing inline quick capture state (`isQuickCapturing`, `quickCaptureText`, `skipNextDismiss`) from `ListDetailView`
- [x] 3.2 Add a `@State private var isQuickCapturing = false` and `@State private var quickCaptureText = ""` (uses the shared component)
- [x] 3.3 Place `QuickCaptureRow` as the last element inside the `List`, gated by `isQuickCapturing`
- [x] 3.4 Update FAB action: set `isQuickCapturing = true`, scroll to `"quick-capture"`, focus field
- [x] 3.5 Wire the `onSubmit` callback to call `viewModel?.commitQuickCapture(text: in: listID)`

## 4. Wire QuickCaptureRow into TimelineView (Today/Tomorrow/Upcoming)

- [x] 4.1 Replace the existing private `quickCaptureRow` with the shared `QuickCaptureRow` component for Today/Tomorrow sections
- [x] 4.2 Place `QuickCaptureRow` as the last element inside the section in `todayLikeContent`, gated by `activeCaptureDate != nil`
- [x] 4.3 Update `onChange(of: isQuickCaptureFocused)` to set `activeCaptureDate = nil` on dismiss
- [x] 4.4 Wire `onSubmit` to call `viewModel?.commitQuickCapture(text:captureDate:)` via `commitQuickCapture` and `commitQuickCaptureWithDate`
- [x] 4.5 Pass `dateHint` from `viewModel?.captureDateHint(activeCaptureDate:)` in todayLikeContent
- [x] 4.6 Convert Upcoming sections to use `QuickCaptureRow` as well (per conversation decision)

## 5. Fix sort order: createdAt ascending so new tasks appear above the field

- [x] 5.1 Change `return lhsCreatedAt > rhsCreatedAt` to `return lhsCreatedAt < rhsCreatedAt` in `TimeSegments.swift:183`
- [x] 5.2 Update spec to document sort order change

## 6. Update main spec

- [x] 6.1 Update `openspec/specs/list-inline-capture/spec.md` to reflect field as last row, ascending sort, auto-scroll on + tap, tap-to-dismiss; add Today/Tomorrow, Upcoming, and QuickCaptureRow specs

## 7. Fix gap in DetailView + unified keyboard-aware scroll

- [x] 7.1 Remove unused `rootDropZone` from DetailView (fixes gap between last task and QuickCaptureRow)
- [x] 7.2 Add shared `quickCaptureScroll(isActive:proxy:)` View extension in QuickCaptureRow.swift
- [x] 7.3 Replace inline onChange scroll in DetailView with `.quickCaptureScroll`
- [x] 7.4 Replace inline onChange scroll in TimelineView with `.quickCaptureScroll`

## 8. Verify

- [x] 8.1 Build — exit code 0, no compilation errors
- [ ] 8.2 Manual: List Detail + tap → field at bottom, auto-scrolls (delayed for keyboard), task appears above
- [ ] 8.3 Manual: Today + tap → same behavior
- [ ] 8.4 Manual: Tomorrow + tap → same behavior
- [ ] 8.5 Manual: Upcoming — per-day fields work, per-day scroll
- [ ] 8.6 Manual: Tap away from field → dismisses, text committed
- [ ] 8.7 Manual: Drag-reorder → tasks reorder normally, field stays as last row
- [ ] 8.8 Manual: Empty list → field appears at bottom with empty state above
- [ ] 8.9 Manual: Long list → auto-scroll on + tap brings full row above keyboard
