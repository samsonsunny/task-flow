## Context

TaskFlow currently uses a `TabView` with 4 tabs (Today, Tomorrow, Upcoming, Later/Inbox), each backed by its own `NavigationStack`. The Inbox tab is the sole non-date-based tab, showing undated tasks grouped by list. Moving Inbox to a sidebar requires: (a) replacing the fourth tab with a toolbar button, (b) implementing a slide-in sidebar overlay, (c) updating task creation to be context-aware, and (d) wiring sidebar list selection into the existing navigation stacks.

## Goals / Non-Goals

**Goals:**
- Tab bar reduced to 3 date-oriented tabs: Today, Tomorrow, Upcoming
- Slide-in sidebar accessible via ☰ button and edge-swipe gesture
- Sidebar shows all user lists with task counts and "+ New List"
- List selection from sidebar pushes `ListDetailView` on the current tab's navigation stack
- Floating + button creates tasks contextually: dated when on a date tab, undated when list is selected in sidebar
- Sidebar dismisses on selection, tap-outside, or swipe

**Non-Goals:**
- Drag-and-drop reordering of lists (future concern)
- Multiple sidebar sections (smart lists, etc. — future)
- macOS/iPad sidebar split view (iOS slide-in overlay only)
- Sidebar customization (pin/hide lists)

## Decisions

### Decision: SwiftUI custom overlay sidebar instead of NavigationSplitView

NavigationSplitView is designed for iPad/macOS and doesn't suit iPhone's compact-width idiom. A custom `ZStack` overlay with a sliding HStack matches the ChatGPT pattern and gives full control over animation, tap-outside dismissal, and gesture handling.

**Alternatives considered:**
- `NavigationSplitView` — breaks on iPhone, forces 3-column layout
- `.sheet` with custom presentation — can't slide from leading edge natively
- Third-party sidebar library — unnecessary dependency for a modest overlay

### Decision: Sidebar state & selected list live in an ObservableObject app state

A shared `AppState` observable object holds `isSidebarOpen` and `selectedListId` values that both the sidebar and the content views observe. This avoids complex binding through the tab view.

**Alternatives considered:**
- `@State` on ContentView — works but requires threading through all subviews
- `@Environment` — good for deep views but adds ceremony for a single shared property

### Decision: + button creates tasks contextually based on active tab

When on Today tab, + pre-fills due date = today. When on Tomorrow tab, due date = tomorrow. When on Upcoming tab, opens the editor for user to pick a date. When a list is selected in the sidebar, the task is created undated and assigned to that list. If no list is selected and on a date tab, the task goes to the default Inbox list with the tab's date assigned.

This removes the "where does it go?" ambiguity — the current view context dictates the default.

### Decision: Sidebar pushes to current NavigationStack path

When user taps a list in the sidebar, the sidebar dismisses and `ListDetailView` is pushed onto the current tab's `NavigationStack` path. Each tab already has its own `path` binding, so we append a `.list(id)` route. This keeps the pattern consistent with existing list navigation.

## Risks / Trade-offs

- **Sidebar discoverability** → Mitigation: The ☰ button is a universal convention; first-time users get an onboarding tip
- **Contextual task creation surprises** → Mitigation: Show the date/list assignment in the task row immediately after creation so it's visible; if user taps + on Today but expected no date, they can easily edit
- **Sidebar state loss on tab switch** → Mitigation: `AppState` lives at the `ContentView` level, so sidebar state persists across tab switches
- **Edge-swipe conflicts with navigation back swipe** → Mitigation: Sidebar edge-swipe only activates when sidebar is closed, and only responds from the absolute left edge (< 20pt), leaving the standard back-swipe zone intact
