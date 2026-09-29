## 1. Schema and model

- [ ] 1.1 Add `isLocked: Bool = false` to `ReminderListGroup` in `TaskFlowSchemaV10` in `TaskFlow/Models/TaskItem.swift`; do NOT add a `migrationPlan:` to `ModelContainer` (AGENTS.md, lightweight-migration rule)
- [ ] 1.2 Verify `TaskPreviewData` typealiases still compile against V10 and add a fixture that seeds BOTH areas with lists, tasks, and dated items
- [ ] 1.3 Confirm `ReminderList.defaultForGroup` remains the pointer that marks a bucket, and add a guard so no second list inside a group can carry `defaultForGroup` pointing at it

## 2. Locked-area reconciler

- [ ] 2.1 Add `reconcileLockedAreas(in:)` to `TaskFlow/Models/AreaReconciler.swift` implementing design.md Decision 3 steps 1-5 in order
- [ ] 2.2 Step 1: adopt Work by name, else lowest `sortOrder` then earliest `createdAt`, else seed; force `name = "Work"` and `isLocked = true`
- [ ] 2.3 Step 2: adopt Personal by name excluding the Work group, else seed; force `name = "Personal"` and `isLocked = true`
- [ ] 2.4 Step 3a: for each extra group with a foreign bucket, repoint every task in that bucket to Work's bucket, then delete the emptied bucket
- [ ] 2.5 Step 3b: reparent each extra group's remaining lists to Work and set their `sortOrder = nil`
- [ ] 2.6 Step 3c: delete each extra group only after confirming `listsArray` is empty
- [ ] 2.7 Step 4: call `backfillListSortOrdersIfNeeded` and verify it actually re-ranks (it early-returns unless some list has `sortOrder == nil`)
- [ ] 2.8 Step 5: single `context.save()` wrapped in `do/catch` with `rollback()` on throw
- [ ] 2.9 Update `seedDefaultAreas` to set `isLocked = true` on both seeded areas
- [ ] 2.10 Re-point the nil-list task sweep at Work's bucket instead of the first group
- [ ] 2.11 Invoke the reconciler from `TaskFlow/App/ContentView.swift` on appear, before any view reads area state

## 3. Remove area CRUD

- [ ] 3.1 Delete `createGroup`, `renameGroup`, `deleteGroup`, `moveGroups`, and `assignListToGroup` from `TaskFlow/Features/Lists/ListViewModel.swift`
- [ ] 3.2 Guard every remaining list mutation in `ListViewModel` against a locked parent; refuse and no-op rather than throw
- [ ] 3.3 Delete `TaskFlow/Features/Lists/GroupCreationSheet.swift`
- [ ] 3.4 Delete `TaskFlow/Features/Lists/MiniCreationSheet.swift`
- [ ] 3.5 Remove the "Create New Group" and "Move to Group" entries from the list row context menu in `ListView.swift`
- [ ] 3.6 Remove the group picker from `TaskFlow/Features/Lists/ListCreationSheet.swift`; keep the name field and the keyboard-safe toolbar; add copy naming the destination area
- [ ] 3.7 Confirm `deleteGroup`'s unguarded area-and-task wipe has no remaining call site

## 4. Capture target and chip

- [ ] 4.1 Replace `CaptureTarget.inbox` with `case area(ReminderListGroup.ID)` in `TaskFlow/Views/Components/CaptureBarViewModel.swift`
- [ ] 4.2 Make capture resolve to `group.inboxBucket` by pointer, undated, with no first-group fallback
- [ ] 4.3 Add the always-visible target chip to `TaskFlow/Views/Components/CaptureBar.swift`, bound to the selected area from `AppState`
- [ ] 4.4 Build the chip menu listing all lists grouped by area, Work then Personal, each area's bucket first, with the current destination checked
- [ ] 4.5 Make the chip update live when the selected area changes
- [ ] 4.6 Keep the capture bar accessible on every pushed surface with the correct target (Home = selected area bucket; time screens = selected area bucket + segment date; list detail = that list)

## 5. Selected-area state

- [ ] 5.1 Add `selectedArea: ReminderListGroup.ID?` to `TaskFlow/App/AppState.swift`, held above the `NavigationStack`
- [ ] 5.2 Default to the first locked area by `sortOrder` then `createdAt`; never persist
- [ ] 5.3 Clear and re-resolve the selection when the underlying group objects are deleted by a merge, so no stale `persistentModelID` is retained
- [ ] 5.4 Confirm the badge service is not given any area filter

## 6. Home feature

- [ ] 6.1 Create `TaskFlow/Features/Home/HomeViewModel.swift` as an `@Observable` class taking `modelContext` at init and receiving data via `update()`
- [ ] 6.2 Compute the selected area's sections: bucket pinned first, then lists by `sortOrder`, each with its uncompleted count
- [ ] 6.3 Compute the selected area's overdue and due-today counts for the summary block, plus the other area's counts for the nudge
- [ ] 6.4 Create `TaskFlow/Features/Home/HomeView.swift` with `@Query` for groups, lists, and tasks; keep collapse state as `@State` only
- [ ] 6.5 Build `AreaSwitcher` as two `Capsule` pills: `primaryAction` fill + `.semibold` when selected, `fillSubtle` + `.medium` when not, `.subheadline` text, 14pt/8pt padding, 0.18s `.easeInOut`
- [ ] 6.6 Verify unselected-pill contrast against `appBackground` in light and dark; add a hairline `border` if `systemFill` on `systemGroupedBackground` is too faint
- [ ] 6.7 Wrap the pills in a horizontal `ScrollView` so both stay reachable at accessibility text sizes on a 320pt-wide device
- [ ] 6.8 Add `.accessibilityHeading` and a selected-state value to each pill; set identifiers `home-area-work`, `home-area-personal`, `home-area-switcher`
- [ ] 6.9 Add `.hoverEffect` and verify focus-chain order for Designed-for-iPad
- [ ] 6.10 Add `.sensoryFeedback(.selection, trigger:)` on pill tap
- [ ] 6.11 Render the summary block with conditional Overdue and Today rows that push the matching time screen
- [ ] 6.12 Render list sections with `TaskRowView`, inline `onToggleCompletion`, swipe actions, and drag reordering
- [ ] 6.13 Attach the capture bar via `safeAreaInset(edge: .bottom)` and apply `.contentMargins(.bottom, AppTheme.captureBarClearance, for: .scrollContent)`
- [ ] 6.14 Build the Home overflow menu: `Select Items`, `Completed`, `Settings`
- [ ] 6.15 Verify no `+` affordance exists anywhere in Home's header or section headers

## 7. Navigation swap

- [ ] 7.1 Replace `NavigationSplitView` with `NavigationStack(path:)` in `TaskFlow/Features/MainTabView.swift`, rooted at `HomeView`
- [ ] 7.2 Add `.navigationDestination` handlers for time segments, list detail, Completed, and Settings
- [ ] 7.3 Set `AppState.selectedArea` above the stack so pushed screens read the same value
- [ ] 7.4 Delete `TaskFlow/Features/Lists/ListView.swift` (`ListsSidebarView`) and remove it from the Xcode project
- [ ] 7.5 Remove the `AppNav` enum and any `columnVisibility` bindings
- [ ] 7.6 Remove the root-level capture `safeAreaInset` from `MainTabView`; each surface now owns its own bar so the bar is never duplicated under a push
- [ ] 7.7 Delete `TaskFlow/Views/Components/QuickCaptureRow.swift` and its project reference (verify zero remaining references first)
- [ ] 7.8 Delete `TaskFlow/Views/Components/SidebarView.swift` if still present

## 8. Area-scoped time views and nudge

- [ ] 8.1 Filter Today / Tomorrow / Upcoming task sets to the selected area
- [ ] 8.2 Add the non-dismissible cross-area nudge row showing the other area's overdue and due-today counts, broken down
- [ ] 8.3 Wire the nudge's "Switch" action to change the selected area while staying on the same segment
- [ ] 8.4 Hide the nudge when the other area has no incomplete task due today or overdue
- [ ] 8.5 Keep the pushed screens' capture bar targeting the selected area's bucket with the segment date applied
- [ ] 8.6 Confirm the app icon badge remains unfiltered across both areas

## 9. Dead code and stale specs

- [ ] 9.1 Cancel `openspec/changes/single-page-home/` (0/25 tasks, superseded design)
- [ ] 9.2 Cancel `openspec/changes/fab-visibility-behavior/` (the FAB no longer exists)
- [ ] 9.3 Archive `openspec/changes/lists-sidebar-split/` as finished
- [ ] 9.4 Amend `openspec/changes/ipad-mac-release/tasks.md:10,20` to drop the sidebar and `columnVisibility` references and add a focus-order check for the area pills
- [ ] 9.5 Grep for and remove any remaining reference to `ListsSidebarView`, `AppNav`, `QuickCaptureRow`, `GroupCreationSheet`, `MiniCreationSheet`, `CaptureTarget.inbox`, `resolveCaptureBucket`, and `createGroup`

## 10. Tests

- [ ] 10.1 Rewrite the sidebar-dependent UI helpers first (3 helpers across `TaskFlowUITests/TaskFlowUITests.swift` and `TaskFlowUITests/TaskFlowSubtasksUITests.swift`) to target the area pills and Home sections
- [ ] 10.2 Update the 8 existing UI tests that assert sidebar navigation to assert Home + area-switch behaviour
- [ ] 10.3 Add unit tests: exactly two locked areas after reconcile; Work adopted by name; Work adopted positionally when renamed; empty store seeds both; single-group store seeds Personal
- [ ] 10.4 Add unit tests for the merge: third area's lists reparented to Work; third area's bucket tasks repointed to Work's bucket; emptied bucket deleted; extra group deleted; no `TaskItem` created, deleted, or property-modified; task count identical before and after
- [ ] 10.5 Add unit tests: merged lists have `sortOrder` backfilled with Work's bucket first; reconcile is idempotent across repeated runs; save failure rolls back
- [ ] 10.6 Add unit tests: locked areas expose no rename or delete path; list rename/delete inside a locked area still works and leaves the area locked
- [ ] 10.7 Update `TaskFlowTests/CaptureBarViewModelTests.swift` for `CaptureTarget.area` — Personal capture never lands in Work; empty store seeds and targets Work; chip menu lists both areas
- [ ] 10.8 Add cross-area move tests: editor retarget moves a task between areas preserving all properties; bulk Move crosses areas
- [ ] 10.9 Add nudge tests: appears for the other area, disappears after switch, hidden when the other area is clear, reports overdue and due-today separately
- [ ] 10.10 Add badge test: badge count is global and does not change when the selected area changes
- [ ] 10.11 Add UI tests: pills render with no Home title, selection animates, pill IDs resolve, overflow reaches Completed and Settings
- [ ] 10.12 Run the full suite: `xcodebuild test -project TaskFlow.xcodeproj -scheme TaskFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'`

## 11. Verification

- [ ] 11.1 Build clean: `xcodebuild build -project TaskFlow.xcodeproj -scheme TaskFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -quiet`
- [ ] 11.2 Manually walk the merge on a store seeded with three areas plus a renamed Work, confirming zero task loss
- [ ] 11.3 Manually verify the capture bar's chip against the confusion this change targets: no second `+`, destination always visible, Personal capture stays in Personal
- [ ] 11.4 Manually verify Dynamic Type at AX sizes, light and dark appearance, and both light and dark unselected-pill contrast
- [ ] 11.5 Verify iPad pointer and keyboard navigation, including full keyboard access through the pills and the overflow menu
- [ ] 11.6 Run `openspec validate home-area-switch --strict`
