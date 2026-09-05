## Why

The current 4-tab `TabView` is a dead-end architecture. It splits the app into four isolated containers — four `NavigationStack`s, four different capture patterns (per-screen FAB, inline date-aware quick-capture rows), and no shared command surface. Every new feature must be squeezed into one of four slots.

The fix is a **single-page layout**: the four primary surfaces become segments under one shared header, on one `NavigationStack`, with **one always-present capture bar** whose target is the selected segment. This buys three concrete things the tab bar can't:

1. **One capture pattern** — a single persistent bar instead of screen-specific FAB/row behaviors, and it's always one tap away.
2. **One navigation stack** — no split identities, `back` always means "back to the segment root".
3. **Zero-tap segment switching** — Today → Upcoming stays a single tap, same as tabs, so task glanceability isn't sacrificed.

This is not the "infinite modules" dashboard from the earlier draft — a segmented control has the same slot ceiling as a tab bar. The honest trade is: we give up the extensibility story (Journal/Notes/Calendar cards) in exchange for a **unified capture + navigation surface**. If the assistant-platform expansion later requires more than 4 slots, that becomes a separate surface decision.

## What Changes

Replace the `TabView` root with a single page: **top segmented control + segment content + persistent bottom capture bar**, all inside one shared `NavigationStack`.

```
[Organize]  [Today]  [Tomorrow]  [Upcoming]      ← top segmented control
─────────────────────────────────────────────
   segment content (the existing views,        ← one shared NavigationStack
   NavigationStack wrappers stripped)              below this
─────────────────────────────────────────────
[●  New reminder —   [target chip ▾]   ]       ← persistent capture bar
```

### Segments

| # | Segment | Content | Push targets |
|---|---|---|---|
| 1 | Organize | `ListsTabView` content (lists, groups, inline creation) | `ListDetailView`, etc. |
| 2 | Today | `ReminderSegmentDetailView(.today)` | task editor via sheet |
| 3 | Tomorrow | `ReminderSegmentDetailView(.tomorrow)` | task editor via sheet |
| 4 | Upcoming | `ReminderSegmentDetailView(.upcoming)` | task editor via sheet |

### Naming: segment is "Organize", list stays "Inbox"

- The 4th segment is **"Organize"** — NOT "Inbox" or "Later". The default list is already named "Inbox" (`ReminderDefaults.defaultListName`); a segment also called "Inbox" would put two "Inbox" labels on one screen (segment + section header + list row).
- "Organize" is already the navigation title of this surface (`ListView.swift`), so no new naming is invented.
- The default **list** keeps the name "Inbox"; capture while in the Organize segment lands in that list.
- **Customer-facing rename:** "Later" → "Organize" touches the App Store listing and marketing articles (AGENTS.md lists "Later" as a customer-facing tab name). Flag for the content pipeline; not part of implementation tasks beyond renaming in-app strings.

### Capture bar

A single **persistent, non-dismissing** bar pinned at the bottom of every screen (segment root AND pushed details — ListDetail, etc.). Target = the selected segment, always resolved and always visible via a tappable target chip.

| Segment | Default target | Chip shows | Tap chip → |
|---|---|---|---|
| Organize | default "Inbox" list, undated | `Inbox` | — (no date) |
| Today | due today | `Today` | date/time picker if needed |
| Tomorrow | due tomorrow | `Tomorrow` | date/time picker if needed |
| Upcoming | nearest upcoming day = `ReminderSegmentLogic.upcomingStart` (D+2) | `Jul 8` (resolved date) | existing `TaskScheduleDatePickerSheet` (`.date` focus) |

**Upcoming semantics (Decision 1):** the bar's default target is D+2 — the horizon start (`TimeSegments.swift:216`). A captured task lands under the first "next week" day section, visibly where the user is looking.

- **One-shot per session:** every capture session defaults to D+2; picking a date via the chip applies to that capture only — no persistent "remembered" date.
- **Midnight rollover:** the chip recomputes via the existing minute-aligned timer path (`scheduleMinuteAlignedTimer`, `TimelineView.swift`); at midnight the horizon slides and the chip follows.
- **Sorting:** new tasks stack under existing same-day tasks by `createdAt` (`defaultSort`, `TimeSegments.swift:195`).
- **Specific-day fast path:** Upcoming keeps its per-day header capture rows for targeting an arbitrary day without the chip.
- **Structural creation stays inline:** the Organize segment's "+ New List / + New Group" rows remain; the bar is *task* capture only.
- Commit is context-blind to the list: tasks captured in any segment go to the default "Inbox" list unless adjusted in the editor.

### Navigation model

- **One shared `NavigationStack`** — all push targets (ListDetail, pushed details) live on it.
- **Segment switch pops to root** and swaps content. No hidden per-segment stacks, no resurrection of a previous segment's depth.
- **Back always means "back to the segment root."**
- **Settings** stays reachable from the toolbar (existing gear/ellipsis), consistent with current per-screen menus.

### FAB removed entirely

- `ReminderFloatingAddButton` overlay in `TimelineView` and the `FloatingAddButton` component are removed — replaced by the persistent capture bar.
- The inline `activeCaptureDate`-driven quick-capture rows in Today/Tomorrow are removed (the bar replaces them). Upcoming's per-day header rows remain (specific-day fast path).

### Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Navigation surface | Top segmented control (4 segments) | Keeps zero-tap day switching — same glanceability as tabs |
| Stack | One shared `NavigationStack`, pop-to-root on switch | No split identities; simple, predictable back |
| Naming | Segment "Organize"; default list "Inbox" | Avoids double-"Inbox"; "Organize" already in code |
| Task creation | Persistent contextual capture bar | One pattern everywhere; always visible; target = segment |
| Capture target visibility | Always-on target chip | The bar never hides its date/list target — no ambiguity |
| Upcoming capture default | D+2 (`upcomingStart`), one-shot | Horizon start; predictable, visible, adjustable via chip |
| Upcoming date pick | Reuse `TaskScheduleDatePickerSheet` | Zero new picker machinery |
| FAB | Removed entirely | Replaced by capture bar; single creation pattern |
| Structural creation | Inline "+ New List / + New Group" rows stay | Bar is task capture only |
| Specific-day capture (Upcoming) | Keep per-day header rows | Fast path for arbitrary dates, complements the bar |
| Midnight handling | Recompute chip on minute-aligned timer | Horizon slides at midnight; chip follows |
| In-flight changes | Cancel `fab-visibility-behavior`; absorb quick-capture + keyboard-chaining into the bar | Avoids throwaway work on a deleted pattern |
| Extensibility | Deferred (future surface decision) | Segmented control has a slot ceiling; honest scope |

### Specs to Replace

- `openspec/specs/app-mental-model/spec.md` — two-axis tab model → single-page segmented model
- `openspec/specs/tab-bar-navigation/spec.md` — TabView requirements → shared NavigationStack + segment switching

### Impact

- `MainTabView.swift` — rewrite: segmented control + shared `NavigationStack` + persistent capture bar
- New `CaptureBar.swift` (or evolve `QuickCaptureRow`) — persistent, focus-owning, target-chip bar
- `TodayView.swift`, `TomorrowView.swift`, `UpcomingView.swift` — strip `NavigationStack` wrappers, keep toolbars
- `ListView.swift` — strip `NavigationStack` wrapper; export segment content
- `TimelineView.swift` — remove FAB overlay + Today/Tomorrow inline quick-capture rows; wire bar; keep Upcoming per-day capture
- `FloatingAddButton.swift` / `ReminderFloatingAddButton` — removed
- `MoreView.swift` — remains pushed from toolbar menus
- All ViewModels, models — unchanged; commit paths reuse existing `commitQuickCapture` / `ReminderSegmentViewModel`