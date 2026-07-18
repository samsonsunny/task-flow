## 1. Reorder HStack in TaskRowView

- [x] 1.1 Move `chevronButton` from before `completionButton` to after `titleView` in the `rowContent` HStack
- [x] 1.2 Verify chevron only renders when `subtaskCount > 0` (unchanged)

## 2. Expand Hit Targets

- [x] 2.1 Add 44×44pt hit target to `completionButton` (visual stays 20×20pt)
- [x] 2.2 Add 44×44pt hit target to `chevronButton` (visual stays 20×20pt)
- [x] 2.3 Ensure hit targets do not overlap on parent tasks

## 3. Verify Multi-line Behavior

- [x] 3.1 Test with long title that wraps to multiple lines — chevron stays vertically centered
- [x] 3.2 Test at various nesting depths — indentation + trailing chevron coexist correctly
- [x] 3.3 Test on all call sites: DetailView, TimelineView, EditorView subtask section
