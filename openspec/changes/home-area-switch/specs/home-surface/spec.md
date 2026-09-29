# home-surface

## Purpose

Define the Home page as the app's root surface: the area-switch navigation bar, capture-bar ownership, the tasks-grouped-by-list body, the Today/Overdue summary, the cross-area nudge, area-scoped time views, and the single-`NavigationStack` navigation model.

## ADDED Requirements

### Requirement: Home is the root surface of a single navigation stack

The app SHALL use a single `NavigationStack` as its only navigation container. `HomeView` SHALL be the root view of that stack. The app SHALL NOT use `NavigationSplitView`, a sidebar column, a bottom `TabView`, or any second navigation surface at the root. Today, Tomorrow, Upcoming, list detail, Completed, and Settings SHALL be reached by pushing onto the root stack from Home.

#### Scenario: App launches into Home
- **WHEN** the app launches
- **THEN** the root view hierarchy SHALL be a `NavigationStack` whose root is `HomeView`
- **AND** the view hierarchy SHALL NOT contain a `NavigationSplitView` or a root `TabView`

#### Scenario: Home is the only entry point
- **WHEN** the user is anywhere in the app
- **THEN** the only way to reach a time segment, a list, Completed, or Settings SHALL be a push from a surface that offers it
- **AND** no tab bar or sidebar SHALL be present to navigate between top-level destinations

#### Scenario: Pushed screens can return to Home
- **WHEN** the user pops the root stack from any pushed screen
- **THEN** `HomeView` SHALL be revealed
- **AND** the selected area SHALL be unchanged from before the push

### Requirement: Area switcher occupies the navigation bar

Home SHALL display the area switcher as a native segmented control in a compact navigation bar and SHALL NOT display a large "Home" title. The switcher SHALL be placed in a `ToolbarItem` with `.principal` placement so it occupies the title slot, which is the only placement wide enough for a segmented control. An overflow menu SHALL be placed in `.topBarTrailing`.

The switcher SHALL be a `Picker` with `.pickerStyle(.segmented)`, one segment per area labelled with the area's name, so it is a platform-standard control rather than a custom imitation. A custom control in a toolbar slot is not used because leading-slot custom content is width-clipped to the point of hiding its own labels, and because a native control supplies pointer, keyboard, and screen-reader behavior without reimplementing it.

The switcher SHALL be disabled while fewer than two areas exist. The switcher SHALL NOT display a task count on either segment. The switcher SHALL expose the accessibility identifier `home-area-switcher`.

#### Scenario: No Home title, switcher in the navigation bar
- **WHEN** the user views Home
- **THEN** the navigation bar SHALL be in compact inline mode with no title text
- **AND** a segmented control labelled "Work" and "Personal" SHALL be visible in the title position
- **AND** an overflow menu button SHALL be visible at the trailing edge

#### Scenario: Selected segment is visually distinct
- **WHEN** the Work area is selected
- **THEN** the "Work" segment SHALL be the selected segment of the control

#### Scenario: Segment taps switch area
- **WHEN** the user taps the "Personal" segment
- **THEN** the "Personal" segment SHALL become the selected segment
- **AND** Home's content SHALL re-scope to Personal

#### Scenario: Switcher is reachable with VoiceOver
- **WHEN** a screen reader navigates to the area switcher
- **THEN** each segment SHALL be announced with its label and selected state
- **AND** the inactive area SHALL be announced as selectable

### Requirement: Selected area is session-scoped and defaults to Work

The selected area SHALL be held in `AppState` above the `NavigationStack` so that both Home and every pushed screen read the same value. The selection SHALL be in-memory only and SHALL NOT be persisted; each app launch SHALL begin with the Work area selected. When the store contains no Work area, the first locked area by `sortOrder` then `createdAt` SHALL be selected.

#### Scenario: Launch always starts on Work
- **WHEN** the user relaunches the app after last viewing Personal
- **THEN** the Work area SHALL be selected
- **AND** Home SHALL show Work's tasks

#### Scenario: Selection is shared with pushed screens
- **WHEN** the user selects Personal on Home
- **AND** pushes the Today time view
- **THEN** the Today view SHALL be scoped to Personal
- **AND** the capture bar on the Today view SHALL target Personal's Inbox

#### Scenario: Selection is not written to disk
- **WHEN** the user selects Personal and the app is terminated
- **THEN** no persisted representation of the selected area SHALL exist
- **AND** the next launch SHALL start on Work

### Requirement: Home lists the selected area's tasks grouped by list

Home SHALL render the selected area's tasks grouped by list. The area's Inbox bucket SHALL be pinned as the first section, followed by the area's remaining lists ordered by `sortOrder`. Each section SHALL show the list name and a count of uncompleted tasks. Tapping a task's completion circle SHALL complete the task in place; tapping the task row SHALL open the task editor.

Each section SHALL be collapsible by tapping its header, and SHALL be expanded by default. Collapsed state SHALL be `@State` held by the view and SHALL NOT be persisted.

Home SHALL use a `List` so that swipe actions and drag reordering are available. The list SHALL apply bottom content margins of `AppTheme.captureBarClearance` so content is never obscured by the capture bar.

#### Scenario: Tasks are grouped under their list
- **WHEN** the user views Home with Work selected
- **THEN** every Work list SHALL appear as a section
- **AND** each section SHALL contain only the tasks whose `reminderList` is that list
- **AND** no Personal task SHALL appear

#### Scenario: Inbox bucket is pinned first
- **WHEN** the user views Home
- **THEN** the selected area's Inbox bucket SHALL be the first section
- **AND** the bucket SHALL display an inbox tray icon
- **AND** remaining lists SHALL follow in their persisted order

#### Scenario: Section header shows uncompleted count
- **WHEN** a list has 3 uncompleted and 2 completed tasks
- **THEN** its section header SHALL display a count of 3

#### Scenario: Completing a task inline
- **WHEN** the user taps the completion circle on a task in a Home section
- **THEN** the task SHALL be marked complete
- **AND** the task SHALL leave the section
- **AND** the section's uncompleted count SHALL decrement

#### Scenario: Sections are collapsible and start expanded
- **WHEN** the user first views Home
- **THEN** every list section SHALL be expanded and show its tasks
- **WHEN** the user taps a section header
- **THEN** that section SHALL collapse and hide its tasks
- **AND** tapping the header again SHALL expand it

#### Scenario: Collapsed state is not persisted
- **WHEN** the user collapses a section and relaunches the app
- **THEN** that section SHALL be expanded

#### Scenario: List content clears the capture bar
- **WHEN** the user scrolls Home to the bottom
- **THEN** the last task row SHALL be fully visible above the capture bar

### Requirement: Home capture bar targets the selected area

Home SHALL own the capture bar as a `safeAreaInset(edge: .bottom)` on its content. A task committed from Home's capture bar SHALL be assigned to the selected area's Inbox bucket, resolved by pointer, with no `dueDate`. The bar SHALL NOT display a destination chip or list-selection menu: retargeting capture into a specific list is the job of the list's own detail screen, and the selected area is already stated by the segmented control in the navigation bar.

Home SHALL NOT display a separate list-creation or group-creation `+` affordance anywhere in its header or sections; the capture bar is the only creation control on the surface.

#### Scenario: Capture lands in the selected area's Inbox
- **WHEN** Personal is selected
- **AND** the user types a title in Home's capture bar and submits
- **THEN** a new `TaskItem` SHALL be created with `reminderList` set to Personal's Inbox bucket
- **AND** its `dueDate` SHALL be `nil`
- **AND** the task SHALL appear in Personal's Inbox section

#### Scenario: Capture bar shows no destination chip
- **WHEN** the user views Home
- **THEN** the capture bar SHALL NOT display a destination chip
- **AND** the capture bar SHALL NOT offer a list-selection menu

#### Scenario: Retargeting capture happens on the list screen
- **WHEN** the user opens a list's detail screen
- **THEN** that screen's capture bar SHALL capture into that list

#### Scenario: Capture never falls back to another area
- **WHEN** the user captures from Home
- **THEN** the task SHALL be assigned to a list in the selected area
- **AND** the resolver SHALL NOT substitute another area's bucket

#### Scenario: No competing add affordance
- **WHEN** the user views Home
- **THEN** no header or section `+` button SHALL be present
- **AND** the capture bar SHALL be the only creation control visible

### Requirement: Home shows a Today and Overdue summary

Home SHALL show a summary block above its list sections containing counts for the selected area's overdue work and its work due today. The Overdue row SHALL be visible only when the selected area has at least one incomplete overdue task. Tapping a summary row SHALL push the corresponding area-scoped time view.

#### Scenario: Overdue count reflects the selected area
- **WHEN** Work has 2 overdue tasks and Personal has 1
- **AND** Personal is selected
- **THEN** the Overdue row SHALL show a count of 1
- **AND** it SHALL not count Work's overdue tasks

#### Scenario: Overdue row hides when the area is clear
- **WHEN** the selected area has no incomplete overdue tasks
- **THEN** the Overdue row SHALL NOT be displayed

#### Scenario: Tapping a summary row pushes a time view
- **WHEN** the user taps the Today summary row
- **THEN** the Today time view SHALL be pushed
- **AND** it SHALL be scoped to the selected area

#### Scenario: Summary counts react to completion
- **WHEN** the user completes the only overdue task in the selected area
- **THEN** the Overdue row SHALL disappear
- **AND** the Today count SHALL decrement if that task was also due today

### Requirement: Time views are area-scoped and reveal other areas' deadlines

Today, Tomorrow, and Upcoming SHALL be pushed from Home and SHALL display only the selected area's tasks. When the non-selected area has incomplete tasks that are due today or overdue, the time view SHALL display a cross-area nudge row naming the other area, the number of affected tasks, and a "Switch" action. Tapping "Switch" SHALL select the other area and SHALL leave the user on the same time segment. The nudge row SHALL NOT be dismissible while the condition holds.

#### Scenario: Time view shows only the selected area
- **WHEN** the user pushes Today with Work selected
- **THEN** only Work tasks due today or overdue SHALL be listed
- **AND** no Personal task SHALL be listed

#### Scenario: Cross-area nudge appears for hidden deadlines
- **WHEN** the user is on Today with Work selected
- **AND** Personal has 3 incomplete tasks due today
- **THEN** a nudge row SHALL appear stating that 3 tasks are due today in Personal
- **AND** the row SHALL offer a "Switch" action

#### Scenario: Switching from the nudge
- **WHEN** the user taps "Switch" on the nudge row
- **THEN** the selected area SHALL become Personal
- **AND** the user SHALL remain on the Today segment
- **AND** the nudge row SHALL no longer be shown

#### Scenario: Nudge is not dismissible
- **WHEN** a cross-area nudge row is displayed
- **THEN** no dismiss or swipe-to-dismiss affordance SHALL be offered
- **AND** the row SHALL remain until the condition no longer holds

#### Scenario: No nudge when the other area is clear
- **WHEN** the other area has no incomplete task due today or overdue
- **THEN** no nudge row SHALL be displayed

#### Scenario: Nudge reflects both overdue and due-today
- **WHEN** the other area has 1 overdue task and 2 tasks due today
- **THEN** the nudge SHALL report 3 affected tasks
- **AND** it SHALL break the count down as overdue and due today

### Requirement: Home overflow menu provides secondary navigation

Home SHALL place an overflow menu in the navigation bar's trailing position. The menu SHALL contain "Completed" and "Settings" entries, SHALL contain "New List" so list creation remains reachable now that the sidebar is gone, and SHALL contain "Select Items" as its first entry to enter bulk selection mode. Tapping "Completed" SHALL push `CompletedView`; tapping "Settings" SHALL push `MoreView`.

#### Scenario: Overflow menu lists secondary destinations
- **WHEN** the user opens Home's overflow menu
- **THEN** "Select Items", "Completed", and "Settings" SHALL be listed

#### Scenario: Completed is reachable
- **WHEN** the user taps "Completed" in the overflow menu
- **THEN** `CompletedView` SHALL be pushed onto the navigation stack

#### Scenario: Settings is reachable
- **WHEN** the user taps "Settings" in the overflow menu
- **THEN** `MoreView` SHALL be pushed onto the navigation stack

#### Scenario: Select Items enters bulk mode on Home
- **WHEN** the user taps "Select Items" in Home's overflow menu
- **THEN** Home SHALL enter selection mode
- **AND** the area switcher SHALL be replaced by a "Done" button
