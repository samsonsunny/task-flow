# Decisions

## Decision: Remove Completion Tracking

**Date:** 2026-02-11

**Decision:** Completion tracking has been removed from TaskFlow. Tasks no longer have a completion state in the UI and are always shown in the main list. The underlying `isCompleted` field remains in the model for backward compatibility with existing local data.

**Rationale:** Completion state introduces extra UI states, filtering logic, and empty-state variants that distract from the core loop of capture → schedule → do. Removing it keeps the app focused on due dates and active work.

**Impact:**
- Completion UI indicators (strikethrough/status text) were removed from `TaskRowView.swift`.
- The list no longer filters out completed tasks in `TaskListView.swift`, and the “All Done” empty state was removed.
- The `isCompleted` field remains in `TaskItem` for backward compatibility but is no longer used by the UI, preserving existing local data without a migration.
- Preview data and the README feature list were updated.

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
