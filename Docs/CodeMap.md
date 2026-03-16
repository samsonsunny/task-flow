# Code Map (Quick Context)

## Entry
- `TaskFlow/App/TaskFlowApp.swift` – app entry
- `TaskFlow/App/ContentView.swift` – top-level view hosting the main screen(s)

## Features
- `TaskFlow/Features/Tasks/TaskList/` – main task list experience (Today/Tomorrow/Upcoming/Someday)
  - `TaskFlow/Features/Tasks/TaskList/TaskListView.swift` – feature composition root + UI state
  - `TaskFlow/Features/Tasks/TaskList/TaskListLogic.swift` – pure helpers (filter/group/sort/key)
- `TaskFlow/Features/Capture/` – capture-related state/policies

## Shared / Design
- `TaskFlow/DesignSystem/` – theme + tokens
- `TaskFlow/Shared/` – shared UI + extensions

## Models
- `TaskFlow/Models/TaskItem.swift` – SwiftData model (shared by features)
