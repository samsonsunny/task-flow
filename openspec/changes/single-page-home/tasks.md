## 1. Single shared NavigationStack

- [ ] 1.1 Rewrite `MainTabView.swift`: remove `TabView` + `AppTab` enum; add top segmented control (`Picker` + `.segmented`, tags Organize/Today/Tomorrow/Upcoming)
- [ ] 1.2 Add one shared `NavigationStack` with a `navigationPath` bound to state; segment switch pops to root
- [ ] 1.3 Strip `NavigationStack` wrappers from `TodayView.swift`, `TomorrowView.swift`, `UpcomingView.swift` (keep toolbars and selection-mode wiring)
- [ ] 1.4 Strip `NavigationStack` wrapper from `ListsTabView` (`ListView.swift`); expose as the Organize segment content
- [ ] 1.5 Verify push flows still work from every segment (ListDetail, editor sheets) and back pops to segment root

## 2. Persistent capture bar

- [ ] 2.1 New `CaptureBar` component: persistent, non-dismissing; focus-owning (like `QuickCaptureRow`); text + notes; target chip in the trailing slot
- [ ] 2.2 Pin `CaptureBar` at the bottom of the segment root AND pushed detail screens
- [ ] 2.3 Per-segment commit: Organize → default "Inbox" list, undated; Today → today; Tomorrow → tomorrow; Upcoming → D+2
- [ ] 2.4 Chip resolves per segment: `Inbox` / `Today` / `Tomorrow` / `ReminderSegmentLogic.upcomingStart` (D+2)
- [ ] 2.5 Upcoming chip tap → existing `TaskScheduleDatePickerSheet` (`.date` focus), one-shot target for that capture session
- [ ] 2.6 Chip recomputes at midnight via the existing minute-aligned timer path

## 3. FAB removal

- [ ] 3.1 Remove `ReminderFloatingAddButton` overlay from `TimelineView.swift`
- [ ] 3.2 Remove `FloatingAddButton.swift` / `ReminderFloatingAddButton` component and all references
- [ ] 3.3 Remove Today/Tomorrow inline `activeCaptureDate`-driven `QuickCaptureRow` rows (bar replaces them)
- [ ] 3.4 Keep Upcoming per-day header capture rows (specific-day fast path)

## 4. Organize segment rename

- [ ] 4.1 Confirm in-app strings: segment label, navigation titles, accessibility identifiers say "Organize"
- [ ] 4.2 Flag "Later" → "Organize" App Store listing + article copy to the content pipeline (AGENTS.md note)

## 5. In-flight change disposition

- [ ] 5.1 Cancel `fab-visibility-behavior` (superseded by FAB removal)
- [ ] 5.2 Carry `quick-capture-keyboard-chaining` requirements into `CaptureBar`
- [ ] 5.3 Absorb useful pieces of `quick-capture-unify-component` (focus ownership, submit/dismiss contract) into `CaptureBar`

## 6. Verify

- [ ] 6.1 Build — exit code 0, no compilation errors
- [ ] 6.2 Manual: segment switching + pop-to-root, push back from ListDetail/editor
- [ ] 6.3 Manual: capture commit per segment (list + date correctness)
- [ ] 6.4 Manual: Upcoming chip target + date picker override
- [ ] 6.5 Manual: midnight chip recompute
- [ ] 6.6 Manual: keyboard chaining while bar has focus (multi-commit without dismiss)
- [ ] 6.7 Regression: selection mode, bulk actions, contexts menus, swipe actions on every segment