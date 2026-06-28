## Why

The Later tab's root view (list-of-lists) was built independently from the shared `ReminderSegmentDetailView` component used by Today/Tomorrow/Upcoming. It uses 16pt font (vs 17pt app standard), tighter vertical spacing, visible list separators, and treats Inbox as just another list row — making it feel visually disconnected from the rest of the app.

## What Changes

1. **Row font 16pt → 17pt** — Align list name font with `TaskRowView`'s 17pt regular title.
2. **Row spacing** — Increase vertical padding and add `listRowInsets` to match the ~26pt row padding of task rows.
3. **Hide row separators** — Remove default `List` separator lines for a cleaner look (consistent with task tabs).
4. **Make Inbox visually distinct** — Differentiate the default inbox list from user-created lists (beyond just the icon swap).
5. **Rename section header** — Change `"LISTS"` to `"Lists"` for the ungrouped section (natural case, descriptive label).
6. **Reorder sections** — Keep ungrouped lists above grouped sections (already the current code behavior; spec will be updated to match).
7. **Thin divider** — Add a visual separator between ungrouped and grouped sections.
8. **Spec updates** — Revise `tab-bar-navigation` and `list-groups` specs to reflect the new layout requirements.

## Capabilities

### New Capabilities
*(None — this is a visual refinement of existing views, no new behavior.)*

### Modified Capabilities
- `tab-bar-navigation`: Inbox pinned-at-top requirement changes to include distinct visual treatment. Ungrouped-above-groups ordering formalized (reverses previous spec).
- `list-groups`: Group display requirements updated to include the thin divider below ungrouped section. Inbox special-treatment requirements added.

## Impact

- `TaskFlow/Features/Lists/ListView.swift` — Row styling, section headers, Inbox row, divider
- `TaskFlow/Features/Lists/ListViewModel.swift` — Potential Inbox-specific computed property
- `openspec/specs/tab-bar-navigation/spec.md` — Layout requirements revised
- `openspec/specs/list-groups/spec.md` — Display requirements revised
