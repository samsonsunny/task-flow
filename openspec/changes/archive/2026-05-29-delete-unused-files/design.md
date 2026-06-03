## Context

TaskFlow uses Xcode 16's file-system-synchronized project management (`PBXFileSystemSynchronizedRootGroup`), meaning Xcode automatically picks up any file on disk within the `TaskFlow/` directory. There is no pbxproj file reference to update when adding or removing files — deletion from the filesystem is sufficient to remove a file from the build.

The 7 files targeted for deletion fall into three categories:
- **Dead infrastructure**: `Spacing.swift` (commented out), `Shadows.swift` (placeholder values, no consumers)
- **Orphaned feature code**: `CaptureSessionState.swift` and `CaptureFocusPolicy.swift` (no consumers; unreferenced `ObservableObject` and its dependency)
- **Superseded/unused components**: `EmptyStateView.swift` (replaced by inline rendering in `ReminderSegmentDetailView`), `CardView.swift` (never adopted), `String+TrailingNewlines.swift` (zero call sites)

No cascading import cleanup is needed — no other file references any type from these files.

## Goals / Non-Goals

**Goals:**
- Remove all 7 unused Swift source files from the repository
- Remove the empty `TaskFlow/Services/` directory
- Verify the project still compiles and tests pass after removal
- Leave no dangling references in the codebase

**Non-Goals:**
- Refactoring or consolidating remaining code
- Adding new tests or functionality
- Changing any runtime behavior

## Decisions

### Decision: Delete files directly — no deprecation cycle
All 7 files have zero consumers. No deprecation warning or staged removal is warranted. Direct deletion is safe and simplifies the codebase immediately.

### Decision: Use `git rm` for clean removal tracking
Using `git rm` ensures the deletions are properly staged in git and removes the files from disk atomically. This also makes the commit history explicit about what was removed and why.

### Decision: Skip spec creation for this cleanup
The `clean-unused-code` capability is an internal code quality concern with no user-facing behavior to specify. The design and tasks fully define the scope. Creating a spec document for "these files shouldn't exist" would add noise without value.

## Risks / Trade-offs

- [A future feature might want the deleted infrastructure] → The files were either placeholder scaffolding (`Spacing.swift`, `Shadows.swift`) or orphaned (`CaptureSessionState.swift`). If needed later, they can be recreated from first principles — the code was not production-grade.
- [Deletion breaks a hidden import dependency] → Zero references confirmed via cross-file grep. Build will catch any missed reference at compile time with a clear error.
- [Xcode project sync behaves unexpectedly] → Xcode 16's filesystem sync removes deleted files from the build automatically. No pbxproj maintenance is needed. A clean build after deletion is the only verification required.
