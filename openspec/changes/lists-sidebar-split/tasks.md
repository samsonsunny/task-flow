## 1. Segment model

- [x] 1.1 Remove the `.organize` case from `HomeSegment` in `MainTabView.swift`
- [x] 1.2 Remove the `.organize` branch from `CaptureBarViewModel.resolveTargetDate`
- [x] 1.3 Verify no other code references `HomeSegment.organize` (grep for `.organize` and `HomeSegment`)

## 2. Root navigation rewrite

- [x] 2.1 Rewrite `MainTabView` as a `NavigationSplitView`: sidebar column = Lists, detail column = `detailColumn`
- [x] 2.2 Add `@State var selectedListID: ReminderList.ID?` (defaults nil) and pass a binding to the sidebar for selection
- [x] 2.3 Build `detailColumn`: `ListDetailView(listID:)` when a list is selected, otherwise the time home (segment picker + segment content)
- [x] 2.4 Extract the existing segment content into a private `timeHome` view: 3-segment `Picker` (`HomeSegment.allCases` without `.organize`) + `content(for:)` switch
- [x] 2.5 Keep the segment-switch pop-to-root behavior and `UITEST_OPEN_UPCOMING` launch-argument default when no list is selected

## 3. Capture host (surface-aware capture bar)

- [x] 3.1 Add `enum CaptureTarget { case segment(HomeSegment); case list(ReminderList.ID) }`
- [x] 3.2 Create `CaptureHost<Content: View>` that owns `CaptureBarViewModel` and attaches `CaptureBar` via bottom `safeAreaInset` of a `NavigationStack`
- [x] 3.3 Route `CaptureBarViewModel.commit` through `CaptureTarget`: `.segment` → segment date + default Inbox list; `.list` → no date + that list
- [x] 3.4 Move the minute-aligned refresh timer out of the old `MainTabView` root into `CaptureHost` (preserving capture-target chip recompute at midnight)
- [x] 3.5 Remove the root-level `safeAreaInset` capture bar from `MainTabView` so the Lists overview never shows it
- [x] 3.6 Wrap both `ListDetailView` and the time home with `CaptureHost` for the correct target resolution

## 4. Lists surface → sidebar

- [x] 4.1 Slim `ListsTabView` into sidebar content: remove `headerAccessory` parameter and its rendering
- [x] 4.2 Remove the capture-bar bottom `contentMargins(.bottom, 72, ...)` from the lists `List`
- [x] 4.3 Add `List(selection:)` binding to the lists `List` and wire row taps to set `selectedListID`
- [x] 4.4 Keep group `DisclosureGroup`s, reorder, create-list/group sheets, and context menus unchanged

## 5. DetailView integration

- [ ] 5.1 Verify `ListDetailView` works as detail-column content (title, toolbar, bulk actions) without its own `NavigationStack`
- [x] 5.2 Reconcile `appState.activeListID` usage: set/clear from `selectedListID` (or remove if no other consumers) per design Open Question
- [ ] 5.3 Confirm capture in list detail commits to the selected list with no date

## 6. Tests

- [ ] 6.1 Update `TaskFlowUITests` and `TaskFlowSubtasksUITests` to the segmented/split model (remove `Later` tab taps and FAB `reminder-create-button` queries)
- [ ] 6.2 Add an assertion that the capture bar is absent on the Lists overview
- [ ] 6.3 Build the app and run the UI test suite