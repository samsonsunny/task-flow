## Context

The app uses a 4-tab `TabView` (Today, Tomorrow, Upcoming, Lists) as its sole navigation surface. During discovery, the product mental model was formalized: the time-based tabs (Today/Tomorrow/Upcoming) form an **attention axis** while the 4th tab is the **home axis** — the permanent organizational home for all tasks, groups, and lists.

The 4th tab is currently named "Lists" and shows `ReminderList` objects optionally grouped by `ReminderListGroup`. The default catch-all list is named "Reminders."

The `ReminderSegment.later` enum case exists but is dead code — no view instantiates `ReminderSegmentDetailView(segment: .later)`. The `.later` case was previously retained for a sidebar that no longer exists.

## Goals / Non-Goals

**Goals:**
- Rename the 4th tab label from "Lists" to "Later" in `MainTabView`
- Rename the default list constant from "Reminders" to "Inbox" and migrate any existing "Reminders" list
- Remove the dead `ReminderSegment.later` case and its filtering logic
- Update the `tab-bar-navigation` spec to reflect the Later tab definition
- Archive the stale `sidebar-navigation` spec

**Non-Goals:**
- No changes to the `Lists/` folder structure (folder rename is cosmetic and can be done in a separate cleanup)
- No changes to `ReminderListGroup` or `ReminderList` data models
- No new project/area data types (future concern)
- No changes to the context menu "Later" action (`TaskRowView.swift:46` — it stays as-is)
- No changes to the time-based tabs or their content

## Decisions

### Decision 1: Constant change + one-time migration for Inbox

**Chosen:** Change `ReminderDefaults.defaultListName` from `"Reminders"` to `"Inbox"` and add a one-time migration in `ContentView.onAppear` that finds any existing `ReminderList` named "Reminders" and renames it to "Inbox."

**Rationale:** The constant drives new-list creation and default-list identification across the app (comparison, filtering, quick-capture assignment). Changing it without migration would cause existing "Reminders" lists to become unrecognized and a duplicate "Inbox" to be created. The migration is a simple `find → rename` with no schema version bump.

### Decision 2: Remove `.later` from enum entirely

**Chosen:** Delete the `case later` from `ReminderSegment`, its associated switch branches (title, icon, tintColor, etc.), and the corresponding `case .later:` branch in `ReminderSegmentLogic.filteredTasks`.

**Alternatives considered:**
- Rename to `.unscheduled`: Adds a case nobody uses. Dead code either way.
- Keep it: Perpetuates confusion about whether "Later" refers to the tab or the filtering concept.

**Rationale:** No view, navigation, or action references `.later`. The only references were in the dead sidebar spec. Removing it eliminates the semantic collision with the renamed tab.

### Decision 3: Tab icons use clock progression + tray

**Chosen:** Update all tab icons to a rhythmic clock progression (simple → motion → compound → container):

| Tab | Icon | Rationale |
|---|---|---|
| Today | `clock.fill` | Simple, one moment |
| Tomorrow | `clock.arrow.2.circlepath` | Motion, cycling to next |
| Upcoming | `calendar.badge.clock` | Plotted on a calendar (unchanged) |
| Later | `tray.full` | Not time — the home, spatial |

**Rationale:** The first three increase in visual complexity along the time axis. Later breaks into a spatial icon (tray), reinforcing the two-axis model (attention vs home) through iconography itself. Custom icons can replace these in the future.

### Decision 4: Navigation title "Later"

**Chosen:** The nav title inside the Later tab is "Later" (replacing "All Lists").

**Rationale:** The other tabs (Today, Tomorrow, Upcoming) also use their tab label as their nav title. "Later" is consistent with that pattern and reinforces the mental model.

### Decision 5: Inbox row icon uses `tray`

**Chosen:** The default "Inbox" list uses `tray` (unfilled) as its row icon. All other lists use `list.bullet`.

**Rationale:** The unfilled tray distinguishes Inbox as the staging/landing zone within the Later tab, while user-created lists retain the `list.bullet` icon. This connects visually to the Later tab's `tray.full` icon.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Existing store has a user-created list named "Inbox" that collides with the renamed default | The migration should check if an "Inbox" already exists before renaming "Reminders" → "Inbox." If collision exists, leave "Reminders" as-is and document the edge case. |
| Removing `.later` from `ReminderSegment` could break build if any third-party or test code references it | All `.later` references were audited during exploration. Tests in `TaskFlowTests.swift` do not reference `.later` — only `.today`, `.tomorrow`, `.upcoming`, `.overdue`. |
| Context menu action label "Later" might confuse users if they think it navigates to the Later tab | The action clears the due date, which causes the task to disappear from time tabs and appear only in Later. The user-perceived effect matches the label — the task ends up in "Later" visibility. |

## Migration Plan

1. Change `ReminderDefaults.defaultListName` constant to `"Inbox"` in `TaskItem.swift`
2. In `ContentView.swift`, before the existing `migrateOrphanedTasks()` call, add:
   - Find `ReminderList` named `"Reminders"` → rename to `"Inbox"` (skip if "Inbox" already exists)
3. Remove `.later` case from `ReminderSegment` enum and all switch branches
4. Remove `case .later:` from `ReminderSegmentLogic.filteredTasks`
5. Update tab label in `MainTabView.swift` from `"Lists"` to `"Later"`
6. Update `tab-bar-navigation` spec
7. Archive `sidebar-navigation` spec
