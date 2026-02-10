# Decisions

## Decision: Remove Onboarding Feature and Associated Cleanup

**Date:** 2026-02-10

**Decision:** The onboarding flow will be removed from the TaskFlow application, and associated unused code will be cleaned up.

**Rationale:** The onboarding experience is designed for first-time users. Since the application is now considered set up, and users are expected to be familiar with its core functionality or will learn through use, the onboarding screens are no longer necessary and add unnecessary complexity to the codebase. Removing this feature will streamline the app's initial load and simplify maintenance. Furthermore, the `@AppStorage` property `sampleTaskCreated`, which was related to initial task seeding, is no longer used and has been removed.

**Impact:**
- The `OnboardingView.swift` file has been deleted.
- `ContentView.swift` has been updated to remove the conditional logic that displays the onboarding screen, along with the `hasOnboarded` flag and the `sampleTaskCreated` property. The `seedSampleTaskIfNeeded` function has also been removed.
- The app will now directly launch into the main task list view (`TaskListView`) for all users.