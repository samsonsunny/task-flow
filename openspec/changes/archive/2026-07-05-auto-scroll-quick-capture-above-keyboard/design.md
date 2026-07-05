## Context

The quick capture row sits as the last row inside each view's `List`. When the keyboard appears, SwiftUI's List automatically adjusts its safe area insets — the scroll view's visible bottom moves above the keyboard. But the `quickCaptureScroll` modifier fires *before* the keyboard animation starts, so the scroll targets the pre-keyboard visible area. Result: row lands behind the keyboard.

## Solution: Two-Phase Scroll

```
Timeline:
FAB tapped
  │
  ├─ Phase 1 (immediate):   scrollTo("quick-capture", .bottom)
  │     Row appears, instant feedback — may be partially behind keyboard
  │
  ├─ keyboard animates up  (List adjusts safe area inset)
  │
  └─ Phase 2 (on didShow): scrollTo("quick-capture", .bottom) again
        Now safe area bottom = above keyboard
        Row lands in correct visible position
```

Because both phases scroll to the same `anchor: .bottom`, and the List's visible area has changed (shrunk by keyboard height), the second scroll naturally moves the row up by exactly the right amount — no keyboard height calculations needed.

## Architecture

```
QuickCaptureRow.swift
  └─ extension View
       └─ func quickCaptureScroll(isActive:proxy:fieldID:)
            ├─ onChange(of: isActive) → Phase 1 scroll
            └─ onReceive(keyboardDidShowNotification) → Phase 2 scroll

ListDetailView                  TimelineView
  └─ .quickCaptureScroll(...)    └─ .quickCaptureScroll(...)
```

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Notification timing | `keyboardDidShowNotification` (not `willShow`) | `willShow` fires before the inset is applied; `didShow` guarantees the List has updated its safe area |
| Animation | `.easeOut(duration: 0.25)` | Matches standard keyboard curve feel; prevents jarring snap |
| Conditional guard | `guard isActive` | Prevents unnecessary scroll when field isn't visible |
| Shared modifier | Keep in existing extension | No new files, no call-site changes |
