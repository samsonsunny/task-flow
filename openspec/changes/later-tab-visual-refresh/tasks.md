## 1. Row Styling — Font, Spacing, Separators

- [x] 1.1 Change list row title font from `.system(size: 16)` to `.system(size: 17, weight: .regular)` in `listRow()` helper
- [x] 1.2 Change group name font from `.system(size: 16, weight: .medium)` to `.system(size: 17, weight: .semibold)` in DisclosureGroup labels
- [x] 1.3 Replace `.padding(.vertical, 4)` with `listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))` on all list rows (Inbox, ungrouped, grouped)
- [x] 1.4 Add `.listRowSeparator(.hidden)` to all list rows in the Later tab

## 2. Inbox Visual Distinction

- [x] 2.1 Add a visual treatment to the Inbox row (e.g., subtle background tint, section wrapper, or badge style) that distinguishes it from user-created list rows

## 3. Section Header and Divider

- [x] 3.1 Change "LISTS" section header text to "Lists"
- [x] 3.2 Add a thin `Divider()` between the ungrouped section and the first grouped section, using `AppTheme.colors.divider`
- [x] 3.3 Ensure divider is only visible when both ungrouped and grouped sections are present

## 4. Spec Updates

- [ ] 4.1 Update `openspec/specs/tab-bar-navigation/spec.md` — change "Ungrouped lists SHALL appear below groups" to "above groups", add Inbox distinct treatment requirement
- [ ] 4.2 Update `openspec/specs/list-groups/spec.md` — add thin divider requirement
