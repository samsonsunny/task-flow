## 1. Fix `toggleCompletion` Reactivity

- [x] 1.1 Add `modelContext.save()` after mutation in `toggleCompletion(for:)`
- [x] 1.2 Add `update(tasks:lists:)` call after save to recompute derived state
- [x] 1.3 Add `update(tasks:lists:)` call in the 0.6s `asyncAfter` after removing from `justCompleted`

## 2. Verify

- [x] 2.1 Build the project with `xcodebuild`
- [x] 2.2 Confirm completed task exits after 0.6s (manual: tap complete, observe row fades + scales out)
