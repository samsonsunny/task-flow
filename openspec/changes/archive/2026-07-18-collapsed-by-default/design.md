## Context

Both `ReminderSegmentViewModel` and `ListDetailViewModel` initialize `collapsedTasks` as an empty set, meaning all subtask trees are expanded on view load. The overdue section defaults to `showOverdue = true`. The user wants a calm, collapsed-by-default layout — no persistence, just clean defaults on every view load.

Key issue discovered: `showOverdue` and `collapsedTasks` are ViewModel state, but `onAppear` recreates the ViewModel on certain SwiftUI lifecycle events (tab switches). This causes manual expand/collapse choices to be lost — the ViewModel is replaced with a fresh one, resetting all UI state.

## Goals / Non-Goals

**Goals:**
- All subtask trees collapsed on first render in every view (Today, Tomorrow, Upcoming, Later, Lists)
- Overdue section collapsed by default on the Today tab
- Manual expand/collapse choices persist across tab switches (within a session)
- Clean slate on app restart (no disk persistence)

**Non-Goals:**
- Persisting collapse state across app restarts
- Changing the collapse/expand toggle behavior
- Animating the initial collapse (tasks just appear collapsed)

## Decisions

### Decision 1: Move UI toggle state from ViewModel to View

**Problem:** `showOverdue` and `collapsedTasks` live in the ViewModel. When `onAppear` fires on tab switch, the ViewModel is recreated and these states reset to defaults.

**Approach:** Move `showOverdue` and `collapsedTasks` to `@State` on the View. This ties them to the view's identity, which is preserved across tab switches in SwiftUI's `TabView`. The ViewModel no longer owns these toggle states — it only provides the data (`overdueTasks`, `flatNodes`).

```
Before (fragile):
  ViewModel {
      showOverdue = false        ← reset on recreate
      collapsedTasks = [...]     ← reset on recreate
  }
  onAppear → new ViewModel → state lost

After (stable):
  View {
      @State showOverdue = false     ← tied to view identity
      @State collapsedTasks = [...]  ← tied to view identity
  }
  ViewModel { overdueTasks, flatNodes }  ← data only, recreated safely
  onAppear → new ViewModel → @State survives
```

**Why this is correct per MVVM:** AGENTS.md rule #6: "UI-only state stays in the view." `showOverdue` (section visibility) and `collapsedTasks` (which rows are hidden) are purely visual toggle states — they don't drive any business logic. The ViewModel should provide data; the View decides what to show.

### Decision 2: `collapsedTasks` initialization moves to View

The View initializes `collapsedTasks` with all parent task IDs on first render. Since `@Query` provides the task list directly to the View, the View has the data needed to compute parent IDs without waiting for the ViewModel.

### Decision 3: `showOverdue` default stays `false` in View

Same as before, just owned by the View instead of the ViewModel.

### Decision 4: ListDetailViewModel gets same treatment

`collapsedTasks` in `ListDetailViewModel` moves to `@State` on `ListDetailView`.

## Risks / Trade-offs

- **Slightly larger refactor** than the original `defaultCollapsed` flag approach. But it's architecturally correct and fixes the root cause.
- **New tasks added after initial load** won't be automatically collapsed. The initial collapse happens once; subsequent mutations respect the current state.
- **ViewModel becomes dumber** — it no longer tracks collapse state. This is actually cleaner: ViewModel = data + mutations, View = presentation state.
