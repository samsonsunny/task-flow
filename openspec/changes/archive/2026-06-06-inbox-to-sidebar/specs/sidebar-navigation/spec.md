## ADDED Requirements

### Requirement: Sidebar toggle button
The system SHALL display a hamburger button (☰) in the top-left corner of the navigation bar on all tabs.
The button SHALL use `sidebar.left` SF Symbol when sidebar is closed and `xmark` when open.

#### Scenario: Button appears on all tabs
- **WHEN** user views any tab (Today, Tomorrow, Upcoming)
- **THEN** a ☰ button appears in the top-left of the navigation bar

#### Scenario: Button toggles sidebar
- **WHEN** user taps the ☰ button
- **THEN** the sidebar opens (if closed) or closes (if open)
- **AND** the button icon toggles between ☰ and ✕

### Requirement: Sidebar overlay
The sidebar SHALL slide in from the leading edge as an overlay (not push), covering approximately 75% of the screen width on iPhone and 40% on iPad.
The sidebar SHALL have a semi-transparent backdrop outside its bounds that dismisses on tap.
The sidebar SHALL use a smooth spring animation for open/close.

#### Scenario: Sidebar opens
- **WHEN** user taps ☰ or edge-swipes from the left edge
- **THEN** the sidebar slides in from the left over 300ms with a spring animation
- **AND** a semi-transparent backdrop covers the remaining screen area

#### Scenario: Sidebar dismisses by tapping outside
- **WHEN** the sidebar is open and user taps on the backdrop area
- **THEN** the sidebar slides out and the backdrop fades away

#### Scenario: Sidebar dismisses by swiping
- **WHEN** the sidebar is open and user swipes right-to-left on the sidebar
- **THEN** the sidebar slides out with the swipe gesture

#### Scenario: Edge-swipe gesture opens sidebar
- **WHEN** the sidebar is closed and user swipes from the left screen edge
- **THEN** the sidebar opens

### Requirement: Sidebar content
The sidebar SHALL display:
- A header with "Lists" title
- A list of all user-created lists (from ReminderList model), each showing its name and task count badge
- A default "Inbox" list at the top (for undated tasks not assigned to a specific list)
- A "+ New List" row at the bottom that triggers list creation
- Each list row SHALL be tappable to select and navigate

#### Scenario: Lists are displayed
- **WHEN** user opens the sidebar
- **THEN** all lists are shown with name, icon, and task count
- **AND** the Inbox list appears first showing count of all undated, unassigned tasks

#### Scenario: Create new list from sidebar
- **WHEN** user taps "+ New List" in the sidebar
- **THEN** an inline text field appears for naming the list
- **AND** after confirming, the new list is added and appears in the sidebar

#### Scenario: Sidebar shows empty state
- **WHEN** user has no lists and opens the sidebar
- **THEN** the sidebar shows only the default Inbox list and "+ New List"

### Requirement: Sidebar list selection navigates
Selecting a list from the sidebar SHALL dismiss the sidebar and push `ListDetailView` onto the current tab's navigation stack.
Each tab's NavigationStack path SHALL support a `.list(ReminderList.ID)` route for this purpose.

#### Scenario: Navigate to list detail
- **WHEN** user taps a list in the sidebar
- **THEN** the sidebar dismisses
- **AND** the app pushes to the ListDetailView for that list on the current tab's navigation stack

#### Scenario: Navigate to list from any tab
- **WHEN** user is on Today tab, opens sidebar, and taps a list
- **THEN** the list detail opens while remaining on the Today tab's navigation stack

### Requirement: Sidebar closing on list selection
The sidebar SHALL automatically close after a list is selected.
The sidebar SHALL NOT close when "+ New List" is tapped (stay open while creating).

#### Scenario: Sidebar closes after list selection
- **WHEN** user taps a list in the sidebar
- **THEN** the sidebar closes with animation
- **AND** the backdrop is removed

#### Scenario: Sidebar stays open during list creation
- **WHEN** user taps "+ New List"
- **THEN** the sidebar remains open
- **AND** the new list field becomes active
