## Context

`TaskFlowApp.swift` is the app entry point. It has a `.onAppear` that calls `reschedulePendingOnLaunch` but no lifecycle observer for foreground transitions.

## Goals / Non-Goals

**Goals:**
- Clear delivered notifications every time the app becomes active
- Minimal code change — single observer, single call

**Non-Goals:**
- No badge number management
- No notification authorization changes
- No changes to scheduling or delivery logic

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Hook | `.onChange(of: scenePhase)` | SwiftUI-native, no AppDelegate needed. Triggered on every active transition — covers cold launch, foreground, and return from other apps. |
| API | `removeAllDeliveredNotifications()` | Single call, clears all delivered notifications regardless of identifier. No need to track which task IDs had delivered notifications. |
| Location | Directly in `TaskFlowApp.body` | Simple enough not to extract. No testability concern — the call is a fire-and-forget side effect. |

## Risks / Trade-offs

- [Clears all delivered notifications, including from other apps] → `removeAllDeliveredNotifications()` only clears notifications from *this* app's bundle identifier. Other apps are unaffected.
