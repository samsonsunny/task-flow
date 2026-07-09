## Context

`TaskRowView` is the primary list row component rendered across all task views (Today, Tomorrow, Later, List Detail, Upcoming). Each row displays a title (with link detection), optional notes, metadata, a completion button, and optional collapse/expand chevron.

Current performance issues stem from:

1. **`attributedTitle` creates a new `NSDataDetector` on every body evaluation** — regex compilation + text scanning is expensive and runs per-row per-render
2. **No `Equatable` conformance** — SwiftUI cannot diff `TaskRowView` against its previous state, so every parent state change (timer ticks, query re-evaluations, mutation notifications) forces all visible rows to fully re-evaluate
3. **`listSections` is a computed property** called per-row, allocating a new `[ListSection]` array each time with no `Equatable` conformance
4. **`ListDetailView` fetches all tasks** via `@Query` even though only one list's tasks are displayed
5. **Cascading `onChange` handlers** in `ReminderSegmentDetailView` call `viewModel.update()` on every query re-fire without checking whether data actually changed

## Goals / Non-Goals

**Goals:**

- Eliminate the per-render `NSDataDetector` allocation in `TaskRowView`
- Enable SwiftUI to skip no-op re-renders of `TaskRowView` via `Equatable` conformance
- Stabilize view inputs so SwiftUI's diffing works correctly (stored `listSections` instead of computed)
- Reduce unnecessary data fetching in `ListDetailView`
- Prevent redundant `update()` calls from cascading `onChange` handlers

**Non-Goals:**

- Changing the visual appearance or layout of `TaskRowView`
- Refactoring the ViewModel architecture or introducing new patterns
- Optimizing SwiftData query performance beyond scoping the `@Query`
- Adding lazy loading or virtualization to lists (SwiftUI `List` handles this)

## Decisions

### Decision 1: Cache `NSDataDetector` as a `static let`

**Choice:** Move `NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)` to a `private static let` on `TaskRowView`.

**Why:** `NSDataDetector` compiles a regex internally on init. Caching it once eliminates repeated regex compilation across all row instances. This is the single highest-impact fix.

**Alternative considered:** Pre-compute attributed titles in the ViewModel. Rejected because it would require the ViewModel to know about SwiftUI `AttributedString` rendering concerns, violating MVVM separation.

### Decision 2: Add `Equatable` conformance keyed on identity + visual state

**Choice:** Conform `TaskRowView` to `Equatable` with equality based on: `task.persistentModelID`, `isCompletedVisualState`, `subtaskCount`, `isCollapsed`, `nestingDepth`.

**Why:** SwiftUI uses `Equatable` on view bodies to skip re-renders. By keying on stable identity (`persistentModelID`) and the visual-affecting inputs, SwiftUI can skip re-renders when nothing visible changed. We intentionally exclude closure parameters (`onToggleCompletion`, etc.) from equality since closures are reference types that change identity on every build — including them would defeat the purpose.

**Alternative considered:** Use `Equatable` on the full `TaskItem` model. Rejected because `@Model` objects use `persistentModelID` for equality, which doesn't detect property changes — but more importantly, we want to skip re-renders when the task's visible state hasn't changed, not when any property changes.

### Decision 3: Store `listSections` in ViewModels as a stored property

**Choice:** Move `listSections` from a computed property to a stored property recomputed inside `update()` / `recompute()`.

**Why:** The computed property allocates a new `[ListSection]` array on every access. Since `TaskRowView` receives it as a parameter, this creates a new array identity on every render, preventing SwiftUI from detecting "no change." Storing it in the ViewModel and only recomputing on `update()` gives it stable identity between mutations.

### Decision 4: Scope `ListDetailView`'s `@Query` to the current list

**Choice:** Replace the blanket `@Query(sort: \TaskItem.sortOrder)` with a `FetchDescriptor` scoped to tasks whose `reminderList?.persistentModelID` matches the current list, fetched in `onAppear` and refreshed on mutation.

**Why:** Fetching all tasks wastes memory and causes the `onChange` cascade to process far more data than needed. However, switching entirely away from `@Query` would lose SwiftData's automatic reactivity. A hybrid approach — using `@Query` but filtering in the ViewModel's `computeTasks()` — preserves reactivity while reducing the working set.

**Alternative considered:** Use `@Query` with a `#Predicate` filter. Rejected because `#Predicate` cannot reference external variables (the list ID) in Swift 5.9 — it requires a `FetchDescriptor` with a closure predicate instead.

### Decision 5: Guard `onChange` handlers with data comparison

**Choice:** In `ReminderSegmentDetailView`, compare the incoming query results against the ViewModel's stored data before calling `update()`.

**Why:** SwiftData's `@Query` can re-fire on unrelated mutations (e.g., editing a task in a different list). Without guards, each re-fire triggers a full `update()` → `rebuildTree()` cycle. A simple identity check (`newTasks !== allTasks`) prevents this.

## Risks / Trade-offs

- **[Risk] Equatable conformance may miss visual updates** → Mitigation: Key equality on all visual-affecting inputs. If a new visual property is added to `TaskRowView` in the future, it must be added to the `Equatable` conformance. Document this requirement in the spec.

- **[Risk] Storing `listSections` may show stale data** → Mitigation: `listSections` is recomputed in every `update()` call, which runs on every mutation. The only scenario where it could be stale is if `lists` changes without triggering `update()` — but the existing `onChange(of: reminderLists)` handler covers this.

- **[Risk] Scoping `ListDetailView` query may miss cross-list task moves** → Mitigation: The `onChange(of: tasks)` handler already re-fetches all tasks. The ViewModel's `computeTasks()` filters by list ID, so moved tasks appear/disappear correctly.

- **[Trade-off] Static `NSDataDetector` lives for the app's lifetime** → Acceptable: it's a small object (~few KB) and link detection is needed for the app's lifetime.
