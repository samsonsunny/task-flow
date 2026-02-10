# Decisions

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
