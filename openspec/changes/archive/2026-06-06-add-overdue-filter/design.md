## Context

Overdue tasks (incomplete, `dueDate < today`) are invisible in every smart filter. The `ReminderSegmentLogic.filteredTasks` method has no case for them — `.today` requires `dueDate == today`, `.tomorrow` requires `dueDate == tomorrow`, `.upcoming` requires `dueDate >= dayAfterTomorrow`, and `.later` requires `dueDate == nil`. A task whose due date was yesterday falls through all four.

The existing `TaskItem.isOverdue` computed property and `TaskUIModel.DatedSection.Kind.overdue` enum case confirm this gap was anticipated but never wired up.

## Goals / Non-Goals

**Goals:**
- Add `case overdue` to `ReminderSegment` enum with all associated switch branches (title, icon, tintColor, empty state, etc.)
- Add filtering logic in `ReminderSegmentLogic.filteredTasks` for `!isCompleted && dueDate < todayStart`
- Add "Overdue" sidebar entry at the top of the smart filters section, conditionally visible only when count > 0
- Use existing `ReminderSegmentDetailView` (tasks are actionable — quick-capture, FAB, swipe actions all work)
- Tab bar whitelist stays at 3 segments (today, tomorrow, upcoming)

**Non-Goals:**
- Not adding Overdue as a tab in `SmartFilterTabbedView`
- Not modifying `TaskItem` data model (existing `dueDate` and `isCompleted` suffice)
- Not changing the existing sidebar-navigation spec's list of smart filters (adding, not replacing)

## Decisions

### Decision 1: Add to ReminderSegment enum over standalone view

**Chosen:** Add `case overdue` to `ReminderSegment` and reuse `ReminderSegmentDetailView`.

**Rationale:** Unlike Completed, overdue tasks are fully actionable — quick-capture, FAB, swipe-to-complete, swipe-to-Today/Tomorrow/Later all make sense. Reusing the existing view is zero-cost and consistent.

**Alternatives considered:**
- Standalone AppNav case + new view: Would duplicate all the row interaction logic already in `ReminderSegmentDetailView`. No benefit.

### Decision 2: Overdue placed first in sidebar

**Chosen:** Overdue sits at the top of the smart filters section, before Today.

**Rationale:** It's the most urgent section — tasks past their due date need attention first. This matches the time-ordered layout (past → present → near future → far future → unscheduled → completed).

### Decision 3: Conditional visibility (appears only when count > 0)

**Chosen:** The Overdue NavigationLink is wrapped in `if count > 0`.

**Rationale:** Overdue is a transient state — ideally zero. Showing an empty "Overdue" entry is noise when everything is on track. Other filters (Today, Tomorrow, etc.) are always visible because they represent consistent time buckets that always exist as concepts.

### Decision 4: Red tint color for urgency

**Chosen:** Overdue uses a red/warning tint color (`AppTheme.colors.destructive` or similar) for both the icon and the count badge, to visually communicate urgency.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Sidebar jumps when Overdue appears/disappears at midnight | Wrapping in conditional `if` means the row insert/remove is animated by SwiftUI. The shift is small (one row at top). Acceptable. |
| User is viewing Overdue when it vanishes (last task rescheduled) | Detail falls through to `case nil` ("Select a list"). Same behavior as deleting a list while viewing it. Acceptable. |
| `isOverdue` uses `Date()` not the view's `now` state | Use the view's `now` (from the refresh timer) for consistency with other segments, not the model's `isOverdue` computed property which uses `Date()`. |
