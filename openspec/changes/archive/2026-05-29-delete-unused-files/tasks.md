## 1. Delete Unused Source Files

- [x] 1.1 Delete `DesignSystem/Spacing.swift` — entire file is commented out
- [x] 1.2 Delete `DesignSystem/Shadows.swift` — placeholder infrastructure, never consumed
- [x] 1.3 Delete `Features/Capture/CaptureSessionState.swift` — orphaned ObservableObject, no consumer
- [x] 1.4 Delete `Features/Capture/CaptureFocusPolicy.swift` — only referenced by orphaned CaptureSessionState
- [x] 1.5 Delete `Views/Components/EmptyStateView.swift` — superseded by inline empty-state rendering
- [x] 1.6 Delete `Views/Components/CardView.swift` — built but never adopted
- [x] 1.7 Delete `Shared/Extensions/String+TrailingNewlines.swift` — `trimmingTrailingNewlines()` has zero call sites

## 2. Remove Empty Directories

- [x] 2.1 Remove `TaskFlow/Services/` — empty directory with no tracked content

## 3. Verify Build Integrity

- [x] 3.1 Run a clean build in Xcode to confirm no compilation errors after deletions
- [x] 3.2 Run all unit and UI tests to confirm they pass with same results as before cleanup
- [x] 3.3 Run `git status` and `git diff` to confirm only the intended files were removed
