## 1. AppState Setup

- [x] 1.1 Create `AppState` ObservableObject with `isSidebarOpen` and `selectedListId` published properties
- [x] 1.2 Inject `AppState` as `@StateObject` in `TaskFlowApp` and pass via `environmentObject` to `ContentView`

## 2. Tab Bar Consolidation

- [x] 2.1 Remove `later` case from `ReminderRootTab` enum in `ContentView.swift`
- [x] 2.2 Remove the `later` tab (`.tag(ReminderRootTab.later)`) and its `laterPath` from `TabView`
- [x] 2.3 Remove `@State private var laterPath` declaration
- [x] 2.4 Add `.toolbar` with leading `sidebar.left` button to each tab's `NavigationStack`
- [x] 2.5 Update `ReminderSegment` `.later` title from "Inbox" to "Undated" (no longer a tab, used only within sidebar context)

## 3. Sidebar Overlay View

- [x] 3.1 Create `SidebarView` component receiving list of `ReminderList` objects and a binding to `selectedListId`
- [x] 3.2 Implement sidebar layout: header ("Lists"), default Inbox row, user list rows with task count badges, "+ New List" row at bottom
- [x] 3.3 Style sidebar with white/surface background, rounded trailing edge, drop shadow
- [x] 3.4 Add inline list creation: tapping "+ New List" shows a `TextField` and "Done" button inline
- [x] 3.5 Connect list creation to SwiftData `modelContext` to persist new `ReminderList`

## 4. Sidebar Overlay Container

- [x] 4.1 Create `SidebarContainer` view modifier using `ZStack` overlay pattern
- [x] 4.2 Implement slide-in animation: sidebar slides from leading edge with spring animation
- [x] 4.3 Add semi-transparent backdrop overlay that responds to tap (dismisses sidebar)
- [x] 4.4 Add drag gesture for interactive swipe-to-dismiss on the sidebar
- [x] 4.5 Add left-edge swipe gesture to open sidebar (only when closed, only from < 20pt edge)
- [x] 4.6 Add environment check: sidebar width 75% on compact width, 40% on regular width

## 5. Sidebar List Selection & Navigation

- [x] 5.1 Add `.list(ReminderList.ID)` case to `ReminderRoute` enum (if not already present)
- [x] 5.2 Add `.navigationDestination(for:)` handler for `.list` route in each tab's `NavigationStack`
- [x] 5.3 Wire sidebar list selection: tap list → dismiss sidebar → append `.list(id)` to current tab's navigation path
- [x] 5.4 Ensure `ListDetailView` receives and displays the correct list

## 6. Contextual Task Creation

- [x] 6.1 Update `ReminderFloatingAddButton` or the + button in each tab to inspect current tab and sidebar selection
- [x] 6.2 Implement context logic: Today tab → dueDate = today, Tomorrow tab → dueDate = tomorrow, Upcoming tab → show full editor
- [x] 6.3 Assign created task to the `selectedListId` from `AppState`, or default Inbox list if none selected
- [x] 6.4 Add quick capture inline row that appears after tapping +, with contextual date hint shown

## 7. Cleanup

- [x] 7.1 Remove the "Inbox" tab icon and title from tab item assets if applicable
- [x] 7.2 Verify sidebar state persists across tab switches (AppState at ContentView level)
- [x] 7.3 Ensure edge-swipe for sidebar doesn't conflict with navigation back-swipe
- [x] 7.4 Update any previews or test fixtures that reference 4-tab layout
