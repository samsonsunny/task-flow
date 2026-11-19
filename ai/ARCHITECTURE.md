# Architecture & Product Model

Load this for architectural, navigation, or new-feature decisions.

## MVVM rules (binding)

1. Views never contain business logic or data mutations. They observe ViewModel state and delegate actions.
2. All ViewModels are `@Observable` classes. Never `ObservableObject` / `@Published`.
3. Views own `@Query` for SwiftData fetching. ViewModels receive data via `update()` — no `@Query` in ViewModels.
4. ViewModels receive `modelContext` at init from the view's `@Environment(\.modelContext)`.
5. ViewModels are co-located with their View in the same feature folder.
6. UI-only state (`@FocusState`, sheet booleans via `@State`, `@Environment(\.dismiss)`) stays in the view.
7. Every mutation calls `update()` **after** `modelContext.save()`. `@Model` objects compare by `persistentModelID`, so `onChange(of:)` cannot see property-only changes. For inserts/deletes, add/remove from `allTasks` before `update()`.

Co-location: `Features/` holds screens (View + ViewModel); `Views/Components/` holds shared UI; `DesignSystem/` holds tokens; `Utilities/` holds stateless helpers; `Models/` holds SwiftData types and reconciliation.

## Product invariants (binding)

If code disagrees with these, the docs are the target — fix the code.

1. Exactly two domains: Work and Personal, represented by `ReminderListGroup` (legacy type name), seeded and locked by `AreaReconciler`. No third domain; users cannot create/rename/delete domains.
2. Root tabs are fixed: Today, Work, Personal, More. No tabs for projects, lists, user groups, or legacy `Later`/`Tomorrow`/`Upcoming`. Same tabs on every device/size class.
3. Projects/lists are optional organization inside a domain. Every `ReminderList` belongs to exactly one domain; its domain is fixed at creation. Projects never become tabs.
4. Today is cross-domain: overdue + due-today from both domains. Future/undated tasks stay in their domain.
5. Each domain owns one protected Inbox bucket. New tasks without a project land there. Identity is domain membership + canonical name `Inbox`; never add a persisted pointer (CloudKit schema is sealed).
6. No new model fields for the domain/project distinction. Extra groups fold into Work on launch, preserving lists and tasks.
7. Customer-facing copy says "Personal", never "Home" (retired display alias). Stored values remain `Work`/`Personal`.
8. No sidebar or `NavigationSplitView` root. Root navigation is the four-tab `TabView`.

Source of truth: `Features/MainTabView.swift`, `Models/AreaReconciler.swift`, `Features/Today/TodayViewModel.swift`, `Features/Areas/AreaTasksViewModel.swift`.

## Stale patterns to reject

- Sidebar navigation, `NavigationSplitView`, project tabs, user-created groups.
- Per-area time views (Work's "Tomorrow", etc.).
- Extending `Features/Home/`, `Features/Tasks/Timeline/`, or the `Today`/`Tomorrow`/`Upcoming` stub views.

`openspec/` was deleted in `0c991b4`; its old change proposals are not authoritative. Do not resurrect them.
