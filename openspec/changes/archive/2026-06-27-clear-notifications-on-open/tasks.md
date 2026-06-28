## 1. Implement

- [x] 1.1 Add `@Environment(\.scenePhase)` to `TaskFlowApp`
- [x] 1.2 Add `.onChange(of: scenePhase)` handler that calls `removeAllDeliveredNotifications()` on `.active`

## 2. Verify

- [x] 2.1 Build the project with `xcodebuild`
- [x] 2.2 Confirm delivered notifications clear on app open (manual: send notification, open app, check tray is empty)
