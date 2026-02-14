# Decisions

## Decision: Lock Task List Iteration 1 Contract

**Date:** 2026-02-14

**Decision:** Task list iteration 1 is locked to a simple, high-clarity model: title-only rows (up to 3 lines), newest-first ordering, and trailing swipe-to-delete. Scrolling while typing is allowed, keyboard dismisses interactively, and draft text remains preserved.

**Rationale:** The list is the second most important feature, so iteration 1 prioritizes readability, predictability, and fast interaction while avoiding unnecessary UI complexity.

**Impact:**
- `TaskListView.swift` now sorts by `createdAt` in reverse order (newest first).
- Task rows now use a 3-line title cap and calmer text styling.
- Trailing swipe delete is available on each task row.
- Iteration-1 list behavior is documented in `Specs/task-list-v1.md`.
- Future ranking enhancements remain scoped to `Specs/task-list-smart-order.md`.

## Decision: Adopt Locked Semantic Color System v1.0

**Date:** 2026-02-14

**Decision:** TaskFlow adopts a locked semantic color system and forbids raw color usage in views. UI color usage is centralized in `DesignSystem/Colors.swift` and backed by named color assets for light/dark variants.

**Rationale:** A strict semantic token contract reduces visual drift, lowers cognitive load, and keeps styling changes safe and fast across the app.

**Impact:**
- New semantic tokens were introduced and standardized: `primaryAction`, `primaryActionPressed`, `appBackground`, `secondaryBackground`, `surface`, `surfaceElevated`, `textPrimary`, `textSecondary`, `textDisabled`, `border`, `divider`, `success`, `warning`, `error`.
- Capture bar styling in `TaskListView.swift` now uses `appBackground` + `surface` + `border` + `textPrimary` + `textDisabled`.
- Opacity-based text coloring was removed from active UI paths.
- Card elevation was changed from colored shadow styling to neutral surface + border styling.
- Design documentation was updated in `Design/DesignRules.md` and `README.md`.

## Decision: Keyboard-First Task Capture (No Inline Add Button)

**Date:** 2026-02-13

**Decision:** Task capture uses a keyboard-first submission flow. In capture mode, the bar is flush to the keyboard with no vertical padding. There is no inline Add button. Users submit with the keyboard `Done` key. The title field wraps visually and grows up to 4 lines. Return acts as submit (not newline insertion), and pasted newline characters are normalized to spaces before save. After submit, the field clears, focus remains in the field, and the keyboard stays open.

**Rationale:** This removes an extra tap target and keeps capture in one continuous action path (type -> Done). A keyboard-flush bar reduces visual and physical distance to the active input surface. The multiline cap supports longer thoughts without adding UI complexity, while newline normalization keeps task titles clean and list-friendly.

**Impact:**
- Capture UX spec was updated in `Specs/task-capture-feature.md` to reflect keyboard-first submission and no inline Add button.
- Capture-mode layout is now defined as keyboard-flush with no vertical gap.
- Input behavior is now explicitly defined: visual wrapping up to 4 lines, Return submits, and pasted newlines are converted to spaces.

## Decision: Keep Completion UI Removed, Hide Completed In Main List

**Date:** 2026-02-14

**Decision:** Completion controls remain removed from the UI, and the main task list now hides tasks where `isCompleted == true`. The `isCompleted` field remains in the model for backward compatibility with existing local data.

**Rationale:** The primary list is an actionable workspace. Excluding completed items improves scan speed and focus while preserving the current minimal interaction model.

**Impact:**
- Completion UI indicators remain removed from `TaskRowView.swift`.
- `TaskListView.swift` now filters the query to exclude completed tasks.
- `TaskItem.isCompleted` remains in the model for store compatibility and migration safety.

## Decision: Add Chip-Based Completion With Timed Revert Window

**Date:** 2026-02-14

**Decision:** The main list uses a leading completion chip as the primary completion control. Tapping the chip sets a temporary completed visual state for 1.8 seconds; tapping again within that window reverts to pending. If not reverted, the task is marked completed and removed from the main list.

**Rationale:** This keeps completion discoverable without adding snackbar UI, preserves a clean list aesthetic, and still provides a short accidental-tap recovery path.

**Impact:**
- `TaskRowView.swift` now renders a 24pt completion chip with a 44pt tap target, plus chip/text state animations.
- Completed visual state uses chip fill + title color/opacity change (no strikethrough).
- `TaskListView.swift` now manages a per-row pending-completion timer and finalizes completion after 1.8 seconds.
- The main query remains active-only (`isCompleted != true`), so finalized tasks leave the primary list.

## Decision: Remove List Sectioning

**Date:** 2026-02-11

**Decision:** The Today/Upcoming/Later section headers were removed from the main task list. Tasks now render as a single due-date-sorted stream.

**Rationale:** Sectioning adds structure and logic that slow scanning and increase UI noise. A single list keeps the app focused on capture and execution without extra categorization.

**Impact:**
- Sectioning logic and headers were removed from `TaskListView.swift`.
- The main list now renders tasks in their natural due-date order.

## Decision: Remove Overdue Labeling

**Date:** 2026-02-11

**Decision:** The overdue status label in each task row has been removed. Due dates remain visible, but no additional overdue text is shown.

**Rationale:** Overdue labels add status noise without changing the core due-date signal. Removing them keeps the row focused on title + date.

**Impact:**
- Overdue status text and color logic were removed from `TaskRowView.swift`.

## Decision: Remove Due Date Display In List

**Date:** 2026-02-11

**Decision:** Due date labels (calendar icon + date text) were removed from task rows. The list now shows titles only.

**Rationale:** Due dates are still used for sorting and scheduling, but the extra row metadata adds visual noise. Removing it keeps the list focused on task titles.

**Impact:**
- Due date label UI was removed from `TaskRowView.swift`.

## Decision: Replace Inline Add With Floating New Task Button

**Date:** 2026-02-11

**Decision:** The inline add row was removed and replaced with a floating “New Task” button that opens a minimal creation sheet.

**Rationale:** Inline add keeps persistent input state on screen and requires focus/keyboard management. A single floating action keeps capture fast while reducing UI and interaction overhead.

**Impact:**
- `InlineAddTaskRow.swift` was removed.
- `TaskListView.swift` now uses a floating button and a quick-add sheet.
- `ContentView.swift` no longer passes inline-add focus state.
- Design-system helpers specific to inline add were removed.

## Decision: Remove Task Row Chevron

**Date:** 2026-02-11

**Decision:** The chevron disclosure icon was removed from each task row.

**Rationale:** With no navigation or detail view, the chevron implied an action that no longer exists. Removing it makes the list more honest and visually cleaner.

**Impact:**
- The trailing chevron was removed from `TaskRowView.swift`.

## Decision: Remove Quick-Add Date Picker (Default Tomorrow)

**Date:** 2026-02-11

**Decision:** The quick-add sheet no longer exposes a due-date picker. New tasks default to Tomorrow.

**Rationale:** For personal users (including couples), a Tomorrow default keeps capture gentle and low-friction without pushing everything into Today. It preserves a light scheduling cadence while removing a decision step.

**Impact:**
- The date picker UI was removed from the quick-add sheet in `TaskListView.swift`.
- New tasks created from quick-add default to Tomorrow.

## Decision: Simplify Quick-Add Sheet Layout

**Date:** 2026-02-11

**Decision:** The quick-add sheet now uses a minimal layout: a title, a single text field, and bottom-aligned Cancel/Add actions. The sheet opens at a compact height with expand options.

**Rationale:** A title-only capture sheet reduces friction for personal users (including couples) and keeps the creation flow fast and lightweight while still allowing expansion when needed.

**Impact:**
- The quick-add sheet UI in `TaskListView.swift` was simplified to a one-field layout.
- The sheet opens at a small height and supports expanding to medium/large.

## Decision: Soften Empty State Icon

**Date:** 2026-02-11

**Decision:** The empty-state icon size was reduced to keep a friendly tone without overpowering the minimalist UI.

**Rationale:** For couples/personal use, a small icon adds warmth and personality. Reducing the size keeps the UI calm and focused.

**Impact:**
- Empty-state icon size was reduced in `EmptyStateView.swift`.

## Decision: Use Subtle Label In Quick-Add Sheet

**Date:** 2026-02-11

**Decision:** The quick-add sheet uses a subtle “New task” label instead of a full-size title.

**Rationale:** Returning users benefit from a lighter, more immediate capture feel, while a small label preserves orientation for new users.

**Impact:**
- The quick-add header label was reduced to caption size in `TaskListView.swift`.

## Decision: Replace Quick-Add Sheet With Inline Overlay

**Date:** 2026-02-11

**Decision:** The quick-add modal sheet was removed and replaced with an inline overlay input bar triggered by the floating button.

**Rationale:** A lightweight overlay keeps capture fast and reduces modal overhead. For personal/couples use, this feels more immediate while preserving a single-step add flow.

**Impact:**
- The quick-add sheet UI was removed from `TaskListView.swift`.
- A bottom overlay input bar with keyboard-aware positioning was added to `TaskListView.swift`.

## Decision: Add Overlay Dismissal And Keyboard Polish

**Date:** 2026-02-11

**Decision:** The inline quick-add overlay now dims the background, supports swipe-down dismissal, and uses a slightly delayed auto-focus for smoother keyboard presentation.

**Rationale:** These small behaviors make the overlay feel intentional and reduce accidental input issues, especially on phones with animation timing differences.

**Impact:**
- Background dim, swipe-down dismiss, and focus timing adjustments were added to `TaskListView.swift`.

## Decision: Revert Inline Overlay To Quick-Add Sheet

**Date:** 2026-02-11

**Decision:** The inline overlay quick-add UI was rolled back in favor of the minimal modal sheet.

**Rationale:** The sheet is more stable, easier to maintain, and simpler to customize long-term. It reduces keyboard edge cases and keeps the creation flow predictable.

**Impact:**
- The overlay input bar and keyboard observer were removed from `TaskListView.swift`.
- The minimal quick-add sheet (240pt starting height) is restored.

## Decision: Remove Task Row Shadows

**Date:** 2026-02-11

**Decision:** Shadows were removed from task rows to keep the list flatter and more minimal.

**Rationale:** Row shadows are decorative and add visual weight. Removing them keeps focus on content and simplifies the styling.

**Impact:**
- The row shadow modifier was removed from `TaskRowView.swift`.

## Decision: Flatten Task Row Styling

**Date:** 2026-02-11

**Decision:** Task rows were changed from card-style blocks to flat list rows with dividers.

**Rationale:** A flat list reduces visual weight and aligns with the minimal, utility-first direction.

**Impact:**
- Row background/rounded card styling was removed in `TaskRowView.swift`.
- Dividers between rows were added in `TaskListView.swift`.

## Decision: Reduce Row Horizontal Padding

**Date:** 2026-02-11

**Decision:** Horizontal padding on task rows was reduced slightly.

**Rationale:** Smaller side padding makes the list feel denser while keeping comfortable tap targets.

**Impact:**
- Horizontal padding in `TaskRowView.swift` was reduced from `sm` to `xs`.

## Decision: Remove No-Overdue Empty State

**Date:** 2026-02-11

**Decision:** The unused “No Overdue Tasks” empty state variant was removed.

**Rationale:** Overdue status is no longer surfaced in the UI, so the variant adds dead code and unnecessary copy.

**Impact:**
- The `noOverdue` case and preview were removed from `EmptyStateView.swift`.

## Decision: Remove List Dividers

**Date:** 2026-02-11

**Decision:** Dividers between task rows were removed.

**Rationale:** The list is meant to feel lightweight; dividers add visual noise without increasing clarity for short titles.

**Impact:**
- Divider rendering in `TaskListView.swift` was removed.

## Decision: Sort By Creation Order

**Date:** 2026-02-11

**Decision:** Task list sorting was changed from due-date order to creation order.

**Rationale:** The list is now a simple capture stream; ordering by creation keeps it predictable and removes date-driven prioritization.

**Impact:**
- The query sort in `TaskListView.swift` now uses `createdAt`.

## Decision: Use Icon-Only Add Action

**Date:** 2026-02-11

**Decision:** The quick-add sheet’s Add action uses an icon instead of text.

**Rationale:** Reduces button chrome and keeps the sheet minimal while preserving a clear primary action.

**Impact:**
- The Add button label in `TaskListView.swift` is now a plus icon.

## Decision: Use Standard Empty-State Icon Size

**Date:** 2026-02-11

**Decision:** The empty-state icon now uses a standard font size instead of a custom size.

**Rationale:** Removes custom sizing logic and keeps the empty state aligned with the app’s typography scale.

**Impact:**
- Empty-state icon sizing in `EmptyStateView.swift` now uses `AppTheme.fonts.title2`.

## Decision: Simplify Empty State To Title Only

**Date:** 2026-02-11

**Decision:** The empty state now shows only the title text, with no icon or subtitle.

**Rationale:** For a minimal experience, removing decorative elements and extra copy keeps the screen calm and focused.

**Impact:**
- Empty-state icon and subtitle were removed from `EmptyStateView.swift`.

## Decision: Remove Floating Button Shadow

**Date:** 2026-02-11

**Decision:** The floating add button no longer uses a shadow.

**Rationale:** The UI is now flat and minimal; shadows add unnecessary visual weight.

**Impact:**
- Shadow styling was removed from the floating add button in `TaskListView.swift`.

## Decision: Remove Quick-Add Cancel Action

**Date:** 2026-02-11

**Decision:** The quick-add sheet no longer shows a Cancel button.

**Rationale:** The sheet can be dismissed via swipe, so removing the button reduces chrome.

**Impact:**
- The Cancel action was removed from the quick-add sheet in `TaskListView.swift`.

## Decision: Strip Quick-Add Sheet Chrome

**Date:** 2026-02-11

**Decision:** The quick-add sheet was reduced to a bare input + Add action with no title, underline, drag indicator, or extra padding. The sheet now uses a fixed 240pt height.

**Rationale:** Further reduces UI chrome and keeps capture minimal and consistent with the stripped-down direction.

**Impact:**
- The “New task” label and input underline were removed from `TaskListView.swift`.
- The Add action now uses a text label.
- Sheet padding and extra detents were removed; only a fixed 240pt height remains.
- The drag indicator was removed.
- A small horizontal inset was added for readability.

## Decision: Stop Normalizing Missing Due Dates

**Date:** 2026-02-11

**Decision:** Tasks with missing due dates are no longer auto-assigned Today on list load.

**Rationale:** The list is now a simple capture stream; silently modifying data adds hidden behavior.

**Impact:**
- The due-date normalization function and its call were removed from `TaskListView.swift`.

## Decision: Remove Reminders & Notifications

**Date:** 2026-02-10

**Decision:** The reminders and notifications feature set (daily review prompts and per-task reminders) will be removed from TaskFlow.

**Rationale:** Reminders add permission prompts, background scheduling, and extra state that complicate the core capture → schedule → complete flow. Removing them keeps the experience lightweight and reduces maintenance overhead.

**Impact:**
- `NotificationManager.swift` has been deleted.
- Reminder UI and permission prompts have been removed from `TaskListView.swift`.
- Reminder controls and scheduling logic have been removed from `TaskDetailView.swift`.
- Task model fields tied to reminders (`remindAt`, `storedReminderReferenceDate`) have been removed.

## Decision: Remove iCloud Sync (CloudKit)

**Date:** 2026-02-10

**Decision:** iCloud sync via CloudKit will be removed, leaving TaskFlow as a local-only SwiftData app.

**Rationale:** Sync adds configuration overhead (entitlements, CloudKit container setup) and introduces failure modes that are not required for the core task flow. Removing it reduces complexity and speeds up iteration.

**Impact:**
- CloudKit configuration was removed from `TaskFlowApp.swift`.
- iCloud entitlements were removed from `TaskFlow.entitlements`.
- Documentation and preview copy were updated to reflect local-only storage.

## Decision: Remove Search

**Date:** 2026-02-10

**Decision:** The search feature has been removed from TaskFlow.

**Rationale:** Search adds UI and empty states that are not essential to the core capture → schedule → complete flow. Removing it keeps the interface minimal.

**Impact:**
- Search-related empty state case and preview were removed from `EmptyStateView.swift`.
- README feature list was updated.

## Decision: Remove Status Badges

**Date:** 2026-02-10

**Decision:** The task status badges (Done/Overdue/Days left) have been removed.

**Rationale:** Status badges are a presentational layer that duplicates existing signals (completion state and due date). Removing them reduces UI noise and keeps the list focused on titles and schedules.

**Impact:**
- `TaskStatusBadge.swift` has been deleted.
- The badge was removed from `TaskDetailView.swift`.
- README feature list was updated.

## Decision: Remove Task Description UI

**Date:** 2026-02-10

**Decision:** Task descriptions are no longer editable or visible in the UI, leaving tasks as title + due date only.

**Rationale:** Descriptions slow down capture and add UI/maintenance overhead without improving the core capture → schedule → complete loop.

**Impact:**
- Description editor UI was removed from `TaskDetailView.swift`.
- Preview seed data was updated to remove descriptions.
- README feature list was updated.

## Decision: Remove Completion Dates From UI

**Date:** 2026-02-10

**Decision:** Completion dates are no longer set or displayed in the UI.

**Rationale:** Completion timestamps are optional metadata that add UI and state complexity without improving the core capture → schedule → complete flow. Removing them keeps the app focused while preserving backward compatibility.

**Impact:**
- The completion date is no longer set in `TaskDetailView.swift`.
- Completion date display was removed from `TaskRowView.swift`.
- Preview seed data was updated.
- README feature list was updated.

## Decision: Hide Completed Tasks In Main List

**Date:** 2026-02-10

**Decision:** Completed tasks are hidden from the main list by default with no filter toggle.

**Rationale:** The primary list is for actionable work. Removing the filter reduces UI state and keeps the focus on active tasks. If users need history, a separate completed-tasks view can be introduced later.

**Impact:**
- The main list now only renders incomplete tasks.
- Completed-task empty states were removed.
- README feature list was updated.

## Decision: Remove Save Status Indicator

**Date:** 2026-02-10

**Decision:** The “Saving / Saved” status indicator has been removed from the task detail screen.

**Rationale:** The indicator adds async state management without changing behavior. Removing it simplifies the UI and code while keeping auto-save intact.

**Impact:**
- Save status state and UI were removed from `TaskDetailView.swift`.

## Decision: Remove Schedule Card Header

**Date:** 2026-02-10

**Decision:** The “Schedule” header in the task detail view has been removed.

**Rationale:** With only due-date controls remaining, the header adds visual weight without providing new information. Removing it keeps the detail view quieter.

**Impact:**
- The header text was removed from the schedule card in `TaskDetailView.swift`.

## Decision: Always-Editable Task Title

**Date:** 2026-02-10

**Decision:** The task title is now always editable; edit mode and the Done button were removed.

**Rationale:** Edit modes add friction and state. Always-editable titles speed up common edits and simplify the toolbar.

**Impact:**
- Edit mode state and toolbar actions were removed from `TaskDetailView.swift`.
- Title input is now always active and saves on dismiss.

## Decision: Remove Delete Action From Detail View

**Date:** 2026-02-10

**Decision:** The delete action was removed from the task detail view. Deletion is available via swipe-to-delete in the task list.

**Rationale:** The detail view should stay minimal, and the delete menu added extra UI for a single action. Keeping deletion in the list reduces clutter and removes a redundant control.

**Impact:**
- The trailing menu and delete confirmation were removed from `TaskDetailView.swift`.

## Decision: Remove Onboarding Feature and Associated Cleanup

**Date:** 2026-02-10

**Decision:** The onboarding flow will be removed from the TaskFlow application, and associated unused code will be cleaned up.

**Rationale:** The onboarding experience is designed for first-time users. Since the application is now considered set up, and users are expected to be familiar with its core functionality or will learn through use, the onboarding screens are no longer necessary and add unnecessary complexity to the codebase. Removing this feature will streamline the app's initial load and simplify maintenance. Furthermore, the `@AppStorage` property `sampleTaskCreated`, which was related to initial task seeding, is no longer used and has been removed.

**Impact:**
- The `OnboardingView.swift` file has been deleted.
- `ContentView.swift` has been updated to remove the conditional logic that displays the onboarding screen, along with the `hasOnboarded` flag and the `sampleTaskCreated` property. The `seedSampleTaskIfNeeded` function has also been removed.
- The app will now directly launch into the main task list view (`TaskListView`) for all users.

## Decision: Remove Completed Tasks View

**Date:** 2026-02-10

**Decision:** The dedicated 'Completed Tasks View' (`CompletedTasksView.swift`) will be removed from the application.

**Rationale:** While the app provides a link to view completed tasks from the main list, the dedicated `CompletedTasksView` offers functionality that is largely covered by the main task list's filtering capabilities and the direct link. Removing this separate view simplifies the app's navigation and reduces codebase complexity. Users can still access completed tasks via the link in the main `TaskListView`.

**Impact:**
- The `CompletedTasksView.swift` file will be deleted.
- The `completedTasksLink` and related properties (`completedTasksCount`, `hasCompletedTasks`) will be removed from `TaskListView.swift`.

## Decision: Remove Overdue Tasks View and Associated Cleanup

**Date:** 2026-02-10

**Decision:** The dedicated 'Overdue Tasks View' (`OverdueTasksView.swift`) will be removed from the application, and all related references will be cleaned up.

**Rationale:** Similar to the removal of the 'Completed Tasks View', the dedicated 'Overdue Tasks View' will be removed to simplify the application's navigation and codebase. The main `TaskListView` provides a prominent link to overdue tasks, and removing the separate view streamlines the user flow. The references in `TaskListView.swift` (enum cases, navigation destinations, and computed properties) have also been removed, ensuring the codebase is clean.

**Impact:**
- The `OverdueTasksView.swift` file has been deleted.
- References in `TaskListView.swift` have been removed, including the `AppScreen.overdue` case, navigation destination, and related variables/properties. The app now focuses on a single, consolidated task list.

## Decision: Remove Overdue Tasks View

**Date:** 2026-02-10

**Decision:** The dedicated 'Overdue Tasks View' (`OverdueTasksView.swift`) will be removed from the application.

**Rationale:** Similar to the removal of the 'Completed Tasks View', the dedicated 'Overdue Tasks View' will be removed to simplify the application's navigation and codebase. The main `TaskListView` provides a prominent link to overdue tasks, and removing the separate view streamlines the user flow.

**Impact:**
- The `OverdueTasksView.swift` file will be deleted.
- References to `OverdueTasksView` in `TaskListView.swift` will be removed, including the `AppScreen.overdue` case, the `overdueTasksLink` variable, the `overdueTasks` computed property, the conditional display of the overdue tasks link in the body, and the `.overdue:` case in the `navigationDestination` switch statement.

## Decision: Require Due Dates (Default Tomorrow)

**Date:** 2026-02-10

**Decision:** All tasks must have a due date. The default due date for new tasks is Tomorrow.

**Rationale:** Strict due dates keep the product focused on the capture → schedule → do loop and eliminate ambiguity. A Tomorrow default keeps capture fast without forcing precise scheduling.

**Impact:**
- The inline add row now always shows due-date controls and defaults to Tomorrow.
- The task detail schedule toggle was removed in favor of an always-on due date.
- Tasks missing a due date are normalized to Today on list load.

## Decision: Remove Task Detail Screen

**Date:** 2026-02-10

**Decision:** The task detail screen (`TaskDetailView.swift`) has been removed.

**Rationale:** With due dates required and descriptions removed, the detail screen adds navigation and UI weight without increasing capability. Keeping everything on the list makes the app faster and calmer.

**Impact:**
- `TaskDetailView.swift` was deleted.
- Task rows no longer navigate to a detail view.
