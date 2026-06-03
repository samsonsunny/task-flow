## Why

TaskFlow has accumulated 7 dead Swift source files — code that is either entirely commented out, orphaned (no consumers), or superseded by newer implementations. These files compile into the binary, add cognitive overhead when navigating the project, and create a misleading impression of the app's actual architecture. Removing them keeps the codebase honest and maintainable.

## What Changes

- Delete `DesignSystem/Spacing.swift` (entire file is commented out)
- Delete `DesignSystem/Shadows.swift` (placeholder infrastructure, never consumed)
- Delete `Features/Capture/CaptureSessionState.swift` (orphaned ObservableObject, no consumer)
- Delete `Features/Capture/CaptureFocusPolicy.swift` (only referenced by the orphaned class above)
- Delete `Views/Components/EmptyStateView.swift` (superseded by inline empty-state rendering)
- Delete `Views/Components/CardView.swift` (built but never adopted)
- Delete `Shared/Extensions/String+TrailingNewlines.swift` (`trimmingTrailingNewlines()` has zero call sites)
- Remove empty `TaskFlow/Services/` directory

No behavioral changes. No public API changes. This is pure deletion with zero runtime effect.

## Capabilities

### New Capabilities
- `clean-unused-code`: Codebase is free of orphaned source files, commented-out placeholder code, and empty directories. All remaining source files have at least one consumer in the project.

### Modified Capabilities

- *(none — no existing specs change)*

## Impact

- 7 Swift source files deleted, ~350 lines removed
- 1 empty directory removed
- Xcode project will auto-sync via filesystem-based file management — no pbxproj changes needed
- No runtime impact: all deleted code was unreferenced
