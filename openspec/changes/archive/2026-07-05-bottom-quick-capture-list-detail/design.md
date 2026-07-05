## Context

Quick capture is currently implemented inline in three views with duplicated boilerplate:

| View | Field position | State owned by | Commit logic |
|------|---------------|----------------|--------------|
| `ListDetailView` | Top of List | Self (`@State`) | `commitQuickCapture` in view |
| `ReminderSegmentDetailView` (Today) | Top of List | Self (`@State`) | `commitQuickCapture` in view |
| `ReminderSegmentDetailView` (Tomorrow) | Top of List | Self (`@State`) | `commitQuickCapture` in view |
| `ReminderSegmentDetailView` (Upcoming) | Per-day section bottom | Self (`@State`) | Same method, per-date |

Each has its own copy of `quickCaptureText`, `skipNextDismiss`, focus management, and dismiss handling.

The previous attempt at a fix applied a pinned VStack approach only to ListDetailView, which was wrong: it broke the pattern, created divergence, and didn't unify anything.

## Goals / Non-Goals

**Goals:**
- Extract a shared `QuickCaptureRow` component that owns its state
- Place it as the **last row** inside each view's `List` (not as a pinned bar outside)
- Auto-scroll to the field on + tap so field + last tasks are in view
- Newly created task appears directly above the field
- Revert the bad pinned-bar change in ListDetailView
- Reduce duplicated code across views

**Non-Goals:**
- Upcoming per-day inline capture (stays as-is — per-day fields in sections)
- Chevron-to-editor path (deferred)
- Changing sort logic (already correct)

## Decisions

### Decision 1: QuickCaptureRow as a self-contained component (replacing Option A from previous design)

```
┌─────────────────────────────────────┐
│  QuickCaptureRow                     │
├─────────────────────────────────────┤
│  Owns:                              │
│    @Binding var text: String        │
│    @FocusState var isFocused        │
│    let onSubmit: () -> Void         │
│    let dateHint: String?            │
│  Renders:                           │
│    HStack { Circle + TextField }    │
│    .id("quick-capture")             │
│    date hint below if present       │
└─────────────────────────────────────┘
```

The parent provides:
- `text` binding (so it can clear on commit externally)
- `onSubmit` callback (the view-specific save logic)
- Optional `dateHint` string (shows "→ Today" etc.)

The component handles:
- Focus management
- Keyboard return → commit
- Transition animation
- `.id()` for scroll anchoring

### Decision 2: Field as last row inside List, not outside

```
Before (my bad change):           After (corrected):
┌────────────────────┐           ┌────────────────────┐
│ VStack             │           │ List                │
│  List { tasks }    │           │  Task A             │
│  .layoutPriority() │           │  Task B             │
│  ─────────────     │           │  ✨ Get milk        │
│  QuickCapture      │  pinned   │  ──────────         │
└────────────────────┘           │  QuickCaptureRow    │  ← last row
                                 └────────────────────┘
```

Rationale: Stays inside the scroll context. The field scrolls with the list, which is fine because auto-scroll on + tap brings it into view. No layout edge cases (safe areas, keyboard avoidance are all handled by SwiftUI's List). Compatible with drag-reorder.

### Decision 3: Auto-scroll on + tap in all views

Each view's FAB action:
1. Set `isQuickCapturing = true` (or equivalent)
2. `proxy.scrollTo("quick-capture", anchor: .bottom)` — scrolls to the last row
3. Focus the field (if using explicit focus binding)

No scroll on creation — user is already at the bottom.

### Decision 4: Upcoming keeps its per-day pattern

Upcoming already has the correct UX: per-day "Add Reminder" CTAs at the bottom of each day section, with inline field appearing within that section. This is a different interaction model (multiple target dates) and does not benefit from a single global field.

## Architecture

```
Parent views                                      Shared component
──────────────                                    ────────────────
ListDetailView                                    QuickCaptureRow
  └─ List                                        ┌─────────────────┐
       ├─ tasks...          ── uses ──▶          │  @State text     │
       └─ QuickCaptureRow                        │  @FocusState is  │
                                                 │  onSubmit(text)  │
ReminderSegmentDetailView                        │  dismiss on tap  │
  (Today/Tomorrow)                               │  dateHint label  │
  └─ List                                        └─────────────────┘
       ├─ tasks...
       └─ QuickCaptureRow

ReminderSegmentDetailView
  (Upcoming)
  └─ List (per-day sections — unchanged)
       └─ per-day quick capture stays
```

## Component Interface

```swift
struct QuickCaptureRow: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void
    let dateHint: String?

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(AppTheme.colors.primaryAction).frame(width: 20, height: 20)
            TextField("New Reminder", text: $text)
                .focused($isFocused)
                .onSubmit(onSubmit)
                .submitLabel(.done)
        }
        .id("quick-capture")
        .padding(.vertical, 9)
        .padding(.horizontal, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .overlay(alignment: .bottomLeading) {
            if let hint = dateHint {
                Text("→ \(hint)").font(.caption).foregroundStyle(AppTheme.colors.textTertiary)
                    .padding(.leading, 32).offset(y: 20)
            }
        }
    }
}
```

## Risks / Trade-offs

- **[Revert risk]** The previous pinned-bar change in DetailView.swift must be reverted. If done incorrectly, list layout could break. → Mitigation: use `git checkout` or carefully compare against the original file from the explore session.
- **[Upcoming divergence]** Upcoming keeps its own per-day fields while others use the shared component. This means two code paths exist. Acceptable because the interaction model is fundamentally different (multiple target dates).
- **[Drag reorder + last row]** The field as last row means the user can't drag a task below the field. That's fine — the field isn't a task, and the rootDropZone (which handles drop-to-root) sits above it. Tasks can be moved to the end of the list normally via drag.
- **[Chevron not implemented]** Already deferred — no change here.
