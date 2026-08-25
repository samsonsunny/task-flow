## Why

The current 4-tab `TabView` is a dead-end architecture — it locks the app into exactly 4 views with no room to grow. The long-term vision is a **personal assistant platform** that expands beyond tasks into journaling, logging, calendar events, notes, and more. A tab bar can't support that.

The solution is a **single-page dashboard** as the app's entry point — a modular surface where each life domain gets a card. New modules (Journal, Calendar, Notes, etc.) can be added over time without restructuring navigation. Individual module pages are pushed from the dashboard via a shared `NavigationStack`.

```
TAB BAR (dead-end)              DASHBOARD (open)
┌───┬───┬───┬───┐              ┌──────────────────────┐
│ T │ T │ U │ L │              │  Module A      [>]   │
├───┴───┴───┴───┤              │  Module B      [>]   │
│               │              │  Module C      [>]   │
│  4 slots max  │              │  Module D      [>]   │
│  (can't grow) │              │  ...                 │
└───────────────┘              │  (infinite)          │
                               └──────────────────────┘
```

The home page is a **glanceable command center** — like iOS widgets — where users see summaries, take quick actions, and tap into full detail pages. It is the foundation for the app's evolution from task manager to personal assistant.

## What Changes

Replace the `TabView` root navigation with a **single-page master-detail** pattern:

### Home page (master)

- **No FAB anywhere** — the FAB is removed from the entire app
- **Persistent capture bar** at the bottom of every screen (home + all detail pages) — like ChatGPT's chat input bar. Always visible, always one tap away. This is the universal task creation pattern.
- **Widget-like summary cards** for each module, some with expanded sizing
- **Settings** → toolbar button (gear icon), opens `MoreView` as sheet
- **Extensible** — new modules can be added as new cards without changing navigation

### Card inventory (task-related modules)

| Card | Content | Size | Notes |
|------|---------|------|-------|
| **Overdue** | Count of overdue tasks + 1-2 titles | Compact | Only shown when tasks are overdue; urgency signal |
| **Today** | Task count + 1-2 task titles | Compact | Core attention card |
| **Tomorrow** | Task count + 1-2 task titles | Compact | Forward-looking |
| **Upcoming** | Task count + next 1-2 tasks | Compact | Week+ horizon |
| **Organize** (renamed from Later) | List names + counts, group overview | **Expanded** | Bigger card — this is the home base for task organization |
| **All Tasks** | Total active task count across all horizons | Compact | Bird's-eye view, tap to see everything |
| **Completed** | Count of tasks completed recently | Compact | Currently buried 3 taps deep — making it discoverable |

### Future modules (not in this change)

- Journal — daily entries, prompts, mood tracking
- Calendar — events, schedule overview
- Notes — quick capture, linked to tasks
- Logging — habits, time tracking, mood
- More TBD

### Card behavior

- **Tap card or chevron** → pushes full detail page onto a single shared `NavigationStack`
- **Checkmarks** on task titles for quick completion (like iOS widget actions)
- **No complex interactions** on cards — no reschedule, no edit, no reorder
- **Empty sections** → collapse or show subtle "All clear" state
- **Module-specific CTAs** — each module defines its own quick actions (future)

### Detail pages

- **Overdue detail** → `ReminderSegmentDetailView(segment: .overdue)` (existing view)
- **Today detail** → `ReminderSegmentDetailView(segment: .today)` (existing view)
- **Tomorrow detail** → `ReminderSegmentDetailView(segment: .tomorrow)` (existing view)
- **Upcoming detail** → `ReminderSegmentDetailView(segment: .upcoming)` (existing view)
- **Organize detail** → existing `ListsTabView` content (list of lists, groups, full management)
- **All Tasks detail** → view showing all active tasks across all time horizons
- **Completed detail** → existing `CompletedView` (recently completed, undo, delete)
- **All detail pages** have the persistent capture bar at the bottom (replaces FAB)
- Back button returns to home

### Navigation model

```
Home (single NavigationStack)
  ├── tap Overdue card    → push OverdueDetail (ReminderSegmentDetailView)
  ├── tap Today card      → push TodayDetail (ReminderSegmentDetailView)
  ├── tap Tomorrow card   → push TomorrowDetail (ReminderSegmentDetailView)
  ├── tap Upcoming card   → push UpcomingDetail (ReminderSegmentDetailView)
  ├── tap Organize card   → push OrganizeDetail (ListsTabView content)
  ├── tap All Tasks card  → push AllTasksDetail
  ├── tap Completed card  → push CompletedDetail (CompletedView)
  └── tap Settings        → sheet MoreView
```

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| FAB | Removed entirely | Replaced by persistent capture bar — cleaner UI, consistent pattern |
| Task creation | Persistent capture bar at bottom of every screen | ChatGPT-style input bar — always visible, one tap away, familiar pattern |
| Card interactivity | Checkmarks only + tap to navigate | Widget-like: minimal actions, not a full list |
| Task titles per card | 1-2 max | Keeps cards compact, glanceable |
| Empty sections | Collapse / "All clear" | Avoids noise, keeps dashboard clean |
| Organize card (ex-Later) | Expanded size, list names + counts | Primary organizational hub — deserves visual prominence |
| Overdue card | Separate card, only when overdue exists | Urgency signal, matches app icon badge logic |
| All Tasks card | Total active count | Bird's-eye view of all work, not just today |
| Completed card | Discoverable on home, not buried in Settings | Currently 3 taps deep — too hidden for a useful feature |
| Navigation | Single shared `NavigationStack` | All detail pages push onto one stack |
| Settings | Toolbar gear icon → sheet | Consistent with existing `MoreView` |
| Deep linking | Out of scope for this change | Notifications open app to home page, no task-level routing |
| Architecture | Modular dashboard | Supports future modules (Journal, Calendar, Notes, etc.) without nav restructuring |

## Specs to Replace

- `openspec/specs/app-mental-model/spec.md` — two-axis model → modular dashboard model
- `openspec/specs/tab-bar-navigation/spec.md` — TabView requirements → NavigationStack + push model

## Impact

- `MainTabView.swift` — rewrite: replace `TabView` with `ScrollView` + summary cards + `NavigationStack`
- New: `HomeView.swift` or inline in `MainTabView` — summary card components
- New: `CaptureBar.swift` — persistent task capture bar component (replaces FAB across entire app)
- `TodayView.swift`, `TomorrowView.swift`, `UpcomingView.swift` — simplify to just `ReminderSegmentDetailView` (remove `NavigationStack` wrapper)
- `ListView.swift` — extract content for use as detail page (no `NavigationStack` wrapper)
- `CompletedView.swift` — may need minor adaptation for push navigation (currently expects to be pushed inside `MoreView`'s `NavigationStack`)
- `FloatingAddButton.swift` — **removed** (replaced by persistent capture bar)
- `ReminderSegmentDetailView.swift` — remove FAB overlay, integrate capture bar
- `ContentView.swift` — no change
- `TaskFlowApp.swift` — no change
- All ViewModels — no change
- All models — no change
