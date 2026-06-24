## Context

The `TaskRowView` component is shared across all list views: `ReminderSegmentDetailView` (Today, Tomorrow, Upcoming, Later, Overdue), `ListDetailView`, and `CompletedView` (which has its own inline row). Currently it shows a truncated title (.lineLimit(2)) and an optional date/time subtitle — no notes, no list name. The `ListDetailView` never passes `showsDueDate`, so date/time is absent there entirely.

The change adds three content layers beneath the completion button and title: notes (multi-line, conditional), and a metadata line (date/time + list name, conditional). This must work across five segment contexts and the list detail view without regressions.

## Goals / Non-Goals

**Goals:**
- Display the full task title (no artificial truncation) in all list views
- Show notes in the row when they exist, hidden when empty
- Show a metadata line with time, date, and list name that adapts to the viewing context
- Enable date/time display in `ListDetailView` for the first time
- Apply completed-state styling uniformly to all row content
- Keep the existing interaction model intact (completion tap, swipe actions, context menu, tap-to-edit)

**Non-Goals:**
- No changes to the editor, data model, or persistence
- No collapsible/expandable row states — content is always shown or always hidden per the rules
- No changes to `CompletedView` row (it has a distinct visual treatment that is intentionally different)
- No changes to the quick-capture row in `ReminderSegmentDetailView`
- No new animations or transitions

## Decisions

### D1: Always-show approach vs collapsible rows
**Chosen: Always show all content**

Alternative considered: Collapsible rows with a tap-to-expand affordance for notes. Rejected because it adds state management complexity, requires an expand/collapse indicator, and hides content that the user explicitly authored. Title and notes grow freely — the user sees exactly what they wrote.

### D2: Metadata as a single combined line
**Chosen: One metadata line with ` · ` separator**

Alternatives considered: (a) Separate lines for each component — wastes vertical space. (b) Right-aligned metadata — inconsistent when multiple components are present. The single line keeps rows compact while showing all relevant context.

### D3: Date omitted from Today/Tomorrow/Upcoming
**Chosen: Hide date in segments where it's communicated by the section header**

In Today, the page title and subtitle communicate the date. In Tomorrow, same. In Upcoming, each section has a day header. Showing the date on every row would be redundant visual noise. Time and list name remain valuable since they aren't conveyed by section context.

### D4: `showsListName` parameter on `TaskRowView`
**Chosen: Add a new `showsListName: Bool` parameter, default `true`**

Avoids leaking view-context awareness into `TaskRowView`. The calling view (segment vs list detail) decides whether list name is relevant. `ListDetailView` passes `false`, all segment views use the default `true`.

### D5: Notes at 14pt `textSecondary`
**Chosen: `system(size: 14, weight: .regular)` with `textSecondary` color**

Matches the visual weight of notes as secondary content. The editor uses the same font size relationship (title at ~title3, notes at body). At 14pt the notes are clearly distinct from the 17pt title while remaining readable.

### D6: Metadata at 13pt `textSecondary`
**Chosen: Reuses the existing date/time font and color**

No change from the current subtitle styling. The metadata line inherits the same 13pt regular weight and secondary color that the date/time subtitle already uses.

## Risks / Trade-offs

- **Row height variability** → Rows with long content can grow tall (e.g. a 20-line title + 20-line notes = ~600pt). This is acceptable — SwiftUI List handles variable-height rows natively, and in practice users rarely write essays in reminder fields. No empty rows are reserved for content that doesn't exist.
- **Increased view tree complexity** → Each row now has up to 3 sub-views where it had 2. The body computation is slightly heavier but still trivial — no images, no complex layout, just Text views.
- **ListDetailView now shows due dates for the first time** → Some users may find this noisy. If so, a future iteration could gate it behind a setting.
- **Consistency with CompletedView** → CompletedView uses a separate inline row that doesn't show notes or metadata (only destination label). If users expect notes there too, it would be a separate change.
