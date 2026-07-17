## Why

Groups already have `sortOrder` and the spec already requires drag-reorder (list-groups/spec.md line 106). The UI just isn't wired — there's no `.onMove` on the groups section in `ListView.swift`. Users want to prioritize groups by position (Work first, Hobbies second, etc.).

## What Changes

- Add `.onMove` to the groups `DisclosureGroup` section in `ListView.swift`
- Add `moveGroups(fromOffsets:toOffset:)` method to `ListsTabViewModel`
- Reuse existing `midpoint(between:and:)` sort algorithm — same pattern as `moveLists`

## Capabilities

### Modified Capabilities
- `list-groups`: Implementation only — spec already covers group reorder at line 106

## Impact

- `ListView.swift` — add `.onMove` to groups section
- `ListViewModel.swift` — add `moveGroups()` method (~20 lines)
