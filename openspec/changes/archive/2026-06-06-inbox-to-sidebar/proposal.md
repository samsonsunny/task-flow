## Why

The current tab bar mixes two navigation paradigms — time-based tabs (Today, Tomorrow, Upcoming) and a list-based tab (Inbox). This creates conceptual friction: the Inbox tab is the odd one out, sharing the same navigational weight as the time-oriented tabs while serving a completely different purpose (organization vs. schedule). Moving lists to a sidebar (accessed via a top-left hamburger button, like ChatGPT) gives each navigation mode a natural home: tabs for "when," sidebar for "where."

## What Changes

- **REMOVE** the Inbox (`later`) tab from the bottom tab bar
  - **BREAKING**: Tab bar reduced from 4 to 3 items: Today, Tomorrow, Upcoming
- **ADD** a hamburger button (☰) in the top-left toolbar of each tab
- **ADD** a slide-in sidebar overlay triggered by the ☰ button (or edge-swipe gesture)
- **MOVE** list browsing and list management into the sidebar
- **UPDATE** task creation behavior so the + button creates tasks in the current context
- **UPDATE** navigation stacks so list selection from sidebar pushes detail views onto the current navigation stack

## Capabilities

### New Capabilities
- `sidebar-navigation`: Slide-in sidebar overlay that displays all user lists (including default Inbox), list counts, and a "+ New List" button. Supports selection, swipe actions, and dismissal via swipe/passthrough-tap.
- `contextual-task-creation`: The floating + button creates tasks based on current context — adds today's date when on Today tab, tomorrow's date when on Tomorrow tab, no date when a specific list is selected in the sidebar, or opens an editor for the user to choose.

### Modified Capabilities
- (none — this proposal introduces new capabilities; no existing specifications are changing)

## Impact

- **ContentView.swift**: TabView reduced to 3 tabs, toolbar buttons added, sidebar overlay state management
- **ReminderSegments.swift**: The `later` segment will no longer be a root tab; its content moves to the sidebar context
- **ReminderSegmentDetailView.swift**: Needs to accept a list parameter and support sidebar-sourced navigation
- **Navigation state**: Each tab's NavigationStack path needs to accept list-detail pushes from the sidebar
- **Task creation flow**: The + button logic needs to inspect current context (tab + sidebar selection) to determine default date/list assignment
- **ListDetailView.swift**: Already exists — used directly from sidebar navigation
