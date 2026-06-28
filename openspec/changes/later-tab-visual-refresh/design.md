## Context

The Later tab root (`ListsTabView`) currently renders a `List` of `ReminderList` items with custom inline row styling. It uses direct `.font(.system(size: 16))` and `.padding(.vertical, 4)` — differing from the app's established 17pt / 26pt row conventions used in `TaskRowView`. The view has three regions: Inbox (default list), ungrouped lists (under "LISTS" header), and grouped lists (DisclosureGroup sections). All three regions share the same row styling, making Inbox indistinguishable from user-created lists.

## Goals / Non-Goals

**Goals:**
- Align list row typography and spacing with the app's 17pt / 26pt row standard
- Remove visual noise from default `List` separators
- Make the Inbox row visually distinct (it's a staging area, not a user-created list)
- Rename the ungrouped section header from "LISTS" to "Lists"
- Add a thin divider between the ungrouped and grouped sections
- Update specs to reflect ungrouped-above-groups ordering (already matches current code)

**Non-Goals:**
- No changes to `ListDetailView` (already uses `TaskRowView` correctly)
- No changes to data model or view model logic
- No changes to context menu actions or list creation flow
- No changes to the tab bar or navigation structure

## Decisions

### D1: Row font 16pt → 17pt
All list and group name labels in the Later root will change to 17pt, matching the `TaskRowView` title font. This affects:
- **List names** (Inbox, ungrouped): `.system(.body)` / 17pt regular — matches task titles exactly
- **Group names** (DisclosureGroup labels): `.system(size: 17, weight: .semibold)` — semibold visually distinguishes container headers from content items
- Count badges remain at 13pt semibold (they are metadata, not titles)

### D2: Row spacing aligned to 26pt standard
Replace `.padding(.vertical, 4)` with `listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))` on each list row, matching the exact pattern used in `ReminderSegmentDetailView.taskListRow()` and `ListDetailView.taskListRow()`.

**Alternative considered**: Keeping `.padding(.vertical, 4)` and adding insets on top. Rejected — the existing `TaskRowView` already has `.padding(.vertical, 10)` internally from its `rowContent`, so the `listRowInsets` of 3+3 gives the true total. Since list rows don't use `TaskRowView`, the insets alone at 3+3 with the content's inline padding is the closest equivalent.

### D3: Hide row separators
Add `.listRowSeparator(.hidden)` to each list row (Inbox, ungrouped, grouped). This matches the task tabs where every row uses `.listRowSeparator(.hidden)`.

The thin divider between ungrouped and grouped sections will be implemented as a `Divider()` inside a section footer/header or as a dedicated `Color.clear` row with a visible divider overlay — whichever renders cleanly without extra section spacing interference.

### D4: Inbox gets distinct visual treatment
The Inbox row will:
- Keep the `tray` icon (already distinct from `list.bullet`)
- Add a subtle background tint or badge-style treatment to communicate "staging area"
- Use the same 17pt font as other rows (consistency) but with slightly different foreground treatment
- Consider: wrapping in a section with a subtle header like "INBOX"

**Alternative considered**: Making Inbox a full-width tappable banner with quick-capture affordance. Rejected for scope — that's a feature enhancement beyond visual refinement.

### D5: Section header "LISTS" → "Lists"
Change the hardcoded `Text("LISTS")` to `Text("Lists")`. This is a one-word change in `ListView.swift`. The `.font(.system(size: 13, weight: .semibold))` styling stays (it matches the metadata font weight convention).

### D6: Thin divider between sections
Add a `Divider()` rendered at the bottom of the ungrouped section (as a section footer) or at the top of the first group section. The divider uses `AppTheme.colors.divider` for consistency with the app's color system.

### D7: Spec updates
- `tab-bar-navigation/spec.md`: Change "Ungrouped lists SHALL appear in a dedicated section below groups" to "Ungrouped lists SHALL appear in a dedicated section above groups." Add Inbox treatment requirement.
- `list-groups/spec.md`: Add requirement for thin divider between ungrouped and grouped sections.

## Risks / Trade-offs

- **[Visual density]** Making all rows 26pt tall reduces the number of visible items per screen, especially for users with many lists. Mitigation: The 26pt standard is well-tested in task tabs — list names are single-line, so vertical space is less critical than task rows which can be multi-line.
- **[Spec drift]** The current code already has ungrouped above groups, so the spec update is formalizing reality rather than changing behavior. No risk.
- **[Inbox treatment scope creep]** "Make Inbox distinct" is intentionally kept minimal. There's a risk the implementation could expand into quick-capture or banner territory. Non-goals section explicitly gates this.
