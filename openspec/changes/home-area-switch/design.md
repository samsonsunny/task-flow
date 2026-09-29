## Context

**Current state.** The root is a `NavigationSplitView` (`MainTabView.swift:44`): the sidebar column is `ListsSidebarView` (titled "My Lists") and the detail column is Today / Tomorrow / Upcoming or a pushed `ListDetailView`. A root-level `safeAreaInset(edge: .bottom)` capture bar renders over **both** columns (`MainTabView.swift:53-57`), so on iPhone — where the sidebar is a pushed screen — the bar appears beneath the list-of-lists. On compact width with the sidebar frontmost, its target silently becomes `.inbox` (`MainTabView.swift:84-86`), which resolves to the **first** area's bucket (`AreaReconciler.swift:125-140`). The sidebar's "Lists" section header carries its own `+` button (`ListView.swift:218-224`), stacking two `+` affordances vertically.

**The model is already general, and users have already used that.** `ReminderListGroup` has no cap. Three live creation paths exist: "Create New Group" in a list row's context menu (`ListView.swift:319-322`), "New Group…" in the move-to-group submenu (`ListView.swift:338-341`), and "New Group…" inside `ListCreationSheet` (`ListCreationSheet.swift:37,72`). Nothing deletes extras — `reconcileAreaInboxes` only sweeps `group == nil` lists and missing buckets.

**Worse, the area set is not even reliably *named*.** `renameGroup` (`ListViewModel.swift:200-205`) has no guard, so Work may have been renamed. `deleteGroup` (`:207-221`) has no guard either and deletes every list **and every task** in an area. The real-world state space is: 0 areas, 1 area, Work renamed to "Job", 2 areas, or 3+ areas, with empty areas mixed in.

**Constraints.**
- iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,6"`) and Mac Catalyst; `ipad-mac-release` is in flight and requires pointer/keyboard parity with no touch-only interactions.
- CloudKit mirroring is live (`TaskFlowApp.swift:79-85`) on schema V10. Model additions use implicit lightweight migration with **no** `migrationPlan:` (AGENTS.md).
- MVVM: `@Observable` ViewModels, `@Query` in views, `modelContext` injected at init, explicit `update()` after every `save()`.
- A bucket is identified by **pointer** (`group.defaultList` / `list.defaultForGroup`), never by name — the invariant `areas-inbox` was written to establish.

## Goals / Non-Goals

**Goals:**
- Make the area the app's top-level mode, visible at all times, and the explicit target of capture.
- Make Home one surface that both captures and displays — no second `+` competing with the capture bar.
- Guarantee every task has a home list in one of exactly two areas, with no task ever deleted or silently lost.
- Keep the two-axis model coherent: area selects *where*, time segment selects *when*.
- Reclaim ~52pt of vertical chrome by collapsing the large title and the switcher into one nav bar.

**Non-Goals:**
- Restoring the old 4-tab `TabView` or any dashboard/modular "infinite modules" layout.
- Reintroducing the pre-tab-bar smart-filter sidebar.
- Changing the schema version or adding a `migrationPlan:`.
- Redesigning the task row, editor, or notification behaviour.
- Persisting the selected area across launches.
- Content/App Store work for any naming change.

## Decisions

### Decision 1: Area switcher in the navigation bar, not a custom header

**Chosen.** Remove the "Home" title. Home uses `.navigationTitle("")` with `.navigationBarTitleDisplayMode(.inline)` — a compact bar with no title — and the two pills sit in it as a `ToolbarItem`, with the overflow menu as `.topBarTrailing`.

```swift
.navigationTitle("")
.navigationBarTitleDisplayMode(.inline)
.toolbar {
    ToolbarItem(placement: .topBarLeading) { AreaSwitcher(selection: $selectedArea) }
    ToolbarItem(placement: .topBarTrailing)  { overflowMenu }
}
```

**Why.** A large title reading "Home" while a pill row beneath reads "Work ●" puts two competing statements about location on one screen, and "Home" is the weaker and less truthful one — the page has two states, not one identity. Collapsing the title and the switcher into one bar also recovers ~52pt (large title ~52pt + switcher inset ~48pt → one 44pt bar).

**Alternatives considered.**
- *Custom full-bleed header* (`.safeAreaInset(edge: .top)` + hidden bar): allows 20pt pill text and rows scrolling under the status bar, but hands us safe-area handling, the scroll blur, rotation, iPad width, and the VoiceOver rotor heading — all of which the nav bar provides free. The *size* gain is ~4pt of type; the *signal* is carried by fill and weight, not size. Rejected.
- *Single area name + chevron menu*: strongest possible mode signal and cheapest, but asymmetric — Personal is invisible until the menu opens, which is poor for a 2-way choice. Rejected.
- *Two plain text labels, no capsules*: lightest visually, weakest active state. Rejected.
- *2-tab `TabView`*: maximum standard-ness, but adds a second navigation surface above the capture bar and recreates the equal-weight two-axis problem `lists-sidebar-split` rejected. Rejected.

**Detail to verify at build time:** `.principal` centres the pills; `.topBarLeading` left-aligns them. Prefer **leading** — every row in the app is left-aligned with a 16pt inset, and centred pills beside a right-side `•••` read as unbalanced.

### Decision 2: Pills, not a system segmented control

**Chosen.** Custom `Capsule` pills: 17pt `.semibold` selected / `.medium` unselected; `AppTheme.colors.primaryAction` fill when selected, `AppTheme.colors.fillSubtle` when not; 14pt horizontal / 8pt vertical padding; 0.18s `.easeInOut` (matching `ListView.swift:184`); `.sensoryFeedback(.selection, trigger:)`.

**Why.** The user asked for the chips promoted to the title's role, and a heavier visual treatment suits that. The mode signal comes from fill contrast and weight.

**Alternatives considered.**
- *`Picker(.segmented)`*: strongest active state and free a11y/pointer support, but cannot render a count badge and reads as a toolbar widget rather than a page identity. The user preferred the pill treatment.
- *Two tappable area cards*: largest target, room for counts, but ~110pt before any task is visible and it visually competes with the list sections below.

**Accepted costs of custom UI** (each is a task, not a freebie): verify unselected-pill contrast against `appBackground` in both appearances and add a `border` hairline if `systemFill` on `systemGroupedBackground` is too faint; supply `.accessibilityHeading`/`.accessibilityValue` so VoiceOver announces "Work, selected" and keeps a rotor heading; add `.hoverEffect` and confirm focus-chain order for Designed-for-iPad; prefer `.subheadline` over a fixed 17pt so the pills scale with Dynamic Type; keep a horizontal `ScrollView` because at AX sizes on a 320pt iPhone SE two 17pt pills plus `•••` overflow.

### Decision 3: Exactly two locked areas, enforced by a recurring reconciler

**Chosen.** `ReminderListGroup` gains `var isLocked: Bool = false`. Work and Personal are `isLocked`. A **recurring** reconciler `reconcileLockedAreas(in:)` runs on every launch from `ContentView.onAppear` and enforces the invariant. All area-creation UI is removed.

```
reconcileLockedAreas(in: context)
 1. work = group(named "Work") ?? first by (sortOrder, createdAt) ?? seed("Work")
    work.name = "Work"; work.isLocked = true
 2. personal = group(named "Personal", ≠ work) ?? seed("Personal")
    personal.isLocked = true
 3. for each extra E in groups − {work, personal}:
      a. if E.defaultList exists and ≠ work.defaultList:
           for task in E.defaultList.remindersArray: task.reminderList = work.defaultList
           delete(E.defaultList)                    // tasks moved, bucket now empty
      b. for list in E.listsArray (non-bucket):
           list.group = work; list.sortOrder = nil   // nil forces re-rank in step 4
      c. delete(E)                                   // E holds no lists by now
 4. backfillListSortOrdersIfNeeded(in: context)      // group → bucket-first → name → createdAt
 5. try context.save()                               // single save; rollback() on throw
```

**Why a reconciler and not a one-time migration.** The codebase's pattern is a `UserDefaults` flag (`did_migrate_global_inbox_to_first_group_v2`). That is wrong here: a second device still running the old build can sync a 3rd area down *after* the flag is set, and a one-shot migration would then strand it with no UI to reach. A reconciler is idempotent, needs no flag, and self-heals. Since area creation is removed, the steady state is two areas and the cost is one fetch.

**Why Work is identified name-first.** The invariant is pointer-based, but area *selection* at migration time is a one-time bootstrap on a store that may predate any lock. `lists-sidebar-split`'s precedent ("first group") uses position. Name-first with a position fallback is deterministic in both cases and matches user intent whenever the name survived. If the promoted group is renamed, step 1 restores the canonical name so the switcher reads correctly.

**Why merge foreign buckets away rather than reparent them.** `ReminderList.defaultForGroup` (`TaskItem.swift:912`) is the pointer that marks a bucket protected. Moving a foreign bucket into Work while `defaultForGroup` still points at the old owner would leave a second, permanently un-renameable list inside Work that is not its group's default — an invariant violation. Merging its tasks into Work's bucket by pointer and deleting the emptied bucket reuses the exact pattern already proven at `AreaReconciler.swift:41-51` and sidesteps the problem entirely.

**Why step 4 is mandatory.** `backfillListSortOrdersIfNeeded` early-returns unless some list has `sortOrder == nil` (`SortOrderBackfill.swift:35`). Merged lists retain theirs, so without nil-ing them the moved lists would interleave arbitrarily with Personal's.

**Why extras are merged rather than kept.** Deliberate product decision: the user wants exactly two domains. The cost is that a user with 3 areas finds lists silently relocated. Accepted, with the mitigations below.

**Alternatives considered.**
- *Dynamic switcher (any number of areas), Work/Personal merely locked*: strictly non-destructive and would have needed no merge. Rejected in favour of a hard two-area model.
- *One-time mapping sheet* ("map each extra area to Work or Personal"): more respectful, but adds a migration UI, resumable state, and a "declined" path for a decision the user chose to make automatically. Rejected.
- *Keep extra areas read-only in a manage screen*: worst of both — hidden complexity without removing the data.

**Safety properties of the merge.** No `TaskItem` is created, deleted, or property-modified — only `reminderList` pointers move, and only for a foreign bucket's tasks. `E` is deleted only after `E.listsArray` is empty, so SwiftData's relationship-nullify behaviour is never load-bearing. A single `save()` with `rollback()` on throw leaves the store untouched on failure. Idempotent: a second run finds two `isLocked` areas and no extras.

### Decision 4: `isLocked` as a persisted flag, not name matching

**Chosen.** A defaulted `Bool` on the model.

**Why.** Name matching is precisely the anti-pattern `areas-inbox` exists to eliminate — with per-area buckets, "Work" is a product constant, but a flag is exact, survives sync, and makes "locked" a data change rather than a code change if that is ever relaxed. A defaulted scalar is a safe lightweight-migration addition, and per AGENTS.md it goes into the latest schema version with **no** `migrationPlan:`.

**Ordering constraint.** `isLocked` must ship **with or before** the UI change. A build that renders the two-pill switcher against a store where neither area is flagged would be inconsistent.

### Decision 5: Capture target is the selected area, with a visible chip

**Chosen.** `CaptureTarget.inbox` is deleted and replaced by `case area(ReminderListGroup.ID)`, resolving to that area's `inboxBucket`, undated. The bar gains an always-visible target chip naming the destination list; its menu is grouped by area so the relationship between switcher and target is explicit at both ends of the screen.

**Why.** The reported confusion is precisely that the bar looks like list creation. Two changes fix it: removing the competing `+` from the header, and naming the target. Replacing `.inbox` also removes the last first-area fallback in the capture path, so a Personal user can no longer have a task silently filed into Work.

**Alternatives considered.**
- *Fold the area switcher into the bar's chip* (one control): the strongest possible fix for the confusion, but it hides the *content filter* in a bottom bar, so the "which area am I looking at" anchor is lost on scroll, and it conflates display scope with capture target. Rejected.
- *Keep `.inbox` as a fallback when the area is unresolved*: reintroduces silent misfiling. Rejected.

### Decision 6: Selected area is in-memory `AppState`, defaults to Work

**Chosen.** `AppState.selectedArea`, held above the `NavigationStack` so the capture bar on pushed screens reads it. Defaults to the first locked area. **Never persisted.**

**Why not persisted.** A `persistentModelID` is not stable across a CloudKit re-install, and a name goes stale on rename. A fresh launch landing on Work is the least surprising default and matches how capture already defaults. Persisting by name *would* be safe now that `reconcileLockedAreas` guarantees the canonical names — recorded here as a deliberate deferral, not an oversight.

**Why in `AppState` and not `@State` in `HomeView`.** The capture bar also renders on pushed Today/list-detail screens. If the selection lived in `HomeView`, those screens would fall back to "no area selected" and reintroduce an implicit default.

### Decision 7: Time views are area-scoped, with a cross-area nudge

**Chosen.** Today / Tomorrow / Upcoming are pushed full screens showing only the selected area's work. When the *other* area has non-empty due-today or overdue work, an area-scoped time view shows a non-dismissible row — "3 due today in Work · Switch" — that switches area and lands on the same segment.

**Why the nudge is mandatory.** Area-scoping a deadline surface creates a genuine hazard: a task due today in Work is invisible while viewing Personal. That is data loss from the user's point of view. The nudge closes the hole without reversing the scoping decision.

**The badge stays global.** `BadgeService` computes overdue + today across all lists and is never area-filtered, so the app icon never under-reports. This is called out in the `task-count-badge` spec so scoping never leaks into it.

**Alternatives considered.**
- *Time views global* (all areas regardless of selection): preserves the pure two-axis model and has no hazard, but makes the area switcher meaningless outside Home. The user chose area scoping; the nudge mitigates it.
- *Sub-tabs for Work/Personal inside each time view*: duplicates the switcher on every screen. Rejected.

### Decision 8: Home lists all of the area's tasks grouped by list

**Chosen.** Home renders one collapsible section per list in the selected area — Inbox bucket pinned first, then remaining lists by `sortOrder` — each showing its tasks inline with `TaskRowView` and `onToggleCompletion`. Sections are collapsed-state `@State` only, all expanded by default.

**Why.** Capture lands in Inbox, so Home is the triage surface; showing the area's whole task set means the user rarely needs to enter list detail to see what they own. Keeping the bucket first preserves the `areas-inbox` pin invariant.

**Constraints.** The `List` is retained (not `ScrollView` + `LazyVStack`) so `.swipeActions` and `.onMove` come for free. Bottom clearance uses the existing `AppTheme.captureBarClearance` (72) via `.contentMargins(.bottom, …)`.

**No counts in the pills.** The section headers already carry counts, matching the existing sidebar capsule; repeating them in the nav bar would clip at large Dynamic Type sizes.

### Decision 9: Tasks can move between areas

**Chosen.** The editor's list picker stays sectioned by area and may target any list in either area, so a task can be moved Work ↔ Personal without leaving the editor.

**Why.** A task's home is its list, and a list's home is its area, so a cross-area move is just a list reassignment. Forbidding it would create a dead end for a task captured into the wrong area — and because capture follows the switcher, that mis-assignment is user-caused and must be correctable. Area identity is a *list* property, not a task property, so no schema change is needed.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| **The merge is silent and irreversible** — a 3rd area's lists land in Work with no notice | Accepted product decision. Tasks are only ever repointed, never deleted or rewritten; sort order is re-ranked deterministically; the reconciler is idempotent so defects surface in tests rather than in the field. |
| `deleteGroup` today wipes an area's **tasks** with no guard | Guarded then deleted in Phase 1; a dedicated test asserts a locked area's tasks cannot be removed via any path. |
| A stale old-build device syncs a 3rd area down after first launch | The recurring reconciler re-merges on the next launch. This is precisely why a flag-based migration was rejected. |
| `isLocked` ships after the UI → inconsistent store | Explicit ordering constraint (Decision 4) enforced by the task ordering. |
| Schema change on a live CloudKit store | `isLocked` is a defaulted scalar; lightweight migration is safe. No `migrationPlan:` added. |
| Custom pills regress accessibility and pointer input | Enumerated as build tasks in Decision 2: contrast check, `.accessibilityHeading`/`.accessibilityValue`, `.hoverEffect`, focus-chain order, scalable type, AX overflow. |
| 3 UI-test helpers and 8 tests break at once | Sequenced last; helper rewrites are the first item in the test phase. |
| `QuickCaptureRow` deletion could break a build we can't see | Verified zero references in `TaskFlow/`, `TaskFlowTests/`, and `TaskFlowUITests/` before scheduling removal. |
| Removing the sidebar orphans `MoreView`/`CompletedView` (already unreachable) | Home's overflow menu becomes their entry point, fixing a pre-existing dead end. |

## Migration Plan

Ordering is load-bearing — the model must be ready before any view reads it.

1. **Schema.** Add `isLocked` to `ReminderListGroup` in `TaskFlowSchemaV10`. No `migrationPlan:`. Lightweight migration applies on next launch.
2. **Reconciler.** Add `reconcileLockedAreas(in:)`; make `seedDefaultAreas` set `isLocked = true`; replace `resolveCaptureBucket` with area-scoped resolution. Invoke from `ContentView.onAppear` **before** any view reads areas.
3. **Area CRUD removal.** Delete `createGroup`, `renameGroup`, `deleteGroup`, `moveGroups`, `assignListToGroup`; guard list operations against locked parents; delete the group sheets and the group picker.
4. **Capture.** Add `CaptureTarget.area`, delete `.inbox`, add the target chip.
5. **Home.** Add `HomeView` + `HomeViewModel`; add a both-areas preview fixture.
6. **Navigation.** Swap `NavigationSplitView` for `NavigationStack(path:)` with `HomeView` root and `.navigationDestination` handlers.
7. **Specs.** Apply the deltas in `specs/`; cancel `single-page-home` and `fab-visibility-behavior`; archive `lists-sidebar-split`; amend `ipad-mac-release/tasks.md:10,20`.
8. **Tests.** Rewrite the sidebar-dependent UI helpers, then add area-lock, merge, and capture-scoping tests.

**Rollback.** Reverting is clean because no `TaskItem` is ever rewritten: the extra areas' lists would be back in their original groups only if the groups were not physically deleted. They *are* deleted, so **the merge is the one irreversible step** — code rollback restores the app, not the pre-merge area structure. Mitigation is sequencing: steps 1–5 are fully reversible and should be verified before step 2's first run against a real store. A pre-merge snapshot test over a seeded 3-area store guards the algorithm, not the user's data.

## Open Questions

- Should the cross-area nudge row be dismissible, or always shown while applicable? Currently specified as non-dismissible so a deadline is never permanently hidden.
- Should the two-pill switcher appear on pushed time views too, or only on Home (with the capture chip carrying area context on other surfaces)? Currently only on Home.
- When a locked area is renamed by a future capability, does `reconcileLockedAreas` step 1 forcibly restore "Work"? Currently yes; a softer rule could preserve a deliberate rename.
