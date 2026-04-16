# TaskFlow


TaskFlow is a SwiftUI task manager for iOS focused on fast task capture and a clean, minimal list experience. Data is stored locally with SwiftData.

## Product Overview

TaskFlow keeps task capture simple: add a task quickly and see it in a calm, scrollable list. The UI emphasizes clarity and low friction.

## Key Features

- Bottom tab navigation: `Today`, `Tomorrow`, `Upcoming`
- Tab-aware filtering for active tasks (today-only, tomorrow-only, and everything else in upcoming)
- Upcoming grouped into planning horizons: `This Week`, `Next Week`, `Later`, `Unscheduled`
- Overdue tasks excluded from `Upcoming`
- Global `+` action to reveal/hide quick capture bar
- Fast continuous capture with keyboard-first submit flow
- Auto due-date assignment based on active tab (`Today`/`Tomorrow`/`Upcoming`)
- `Upcoming` sorting: dated sections by due date (then created time), `Unscheduled` by created time
- Upcoming row rescheduling actions: `Today`, `Tomorrow`, `Schedule`
- No explicit empty-state message in tabs
- Local storage via SwiftData

## Platforms

- iOS

## Data & Sync

TaskFlow uses SwiftData as the local persistence layer. There is no sync enabled at this time.

## Project Structure

- `TaskFlow/App`: App entry point and top-level views
- `TaskFlow/Models`: SwiftData models for tasks
- `TaskFlow/Views`: Screens and reusable UI components
- `TaskFlow/DesignSystem`: App styling, typography, and tokens
- `TaskFlow/Extensions`: Utilities and shared helpers

## Color System

TaskFlow uses semantic color tokens centralized in `TaskFlow/DesignSystem/Colors.swift` and backed by color assets in `TaskFlow/Assets.xcassets`.

- Never use raw hex values in views.
- Use only semantic tokens (`primaryAction`, `appBackground`, `surface`, `textPrimary`, `border`, etc.).
- Avoid opacity-based text coloring; use `textPrimary`, `textSecondary`, and `textDisabled`.
- See `Docs/DesignSystem.md` for the full palette and roles.

## Getting Started

1. Open `TaskFlow.xcodeproj` in Xcode.
2. Select an iOS target.
3. Build and run.

If you want to add sync later, you can reintroduce CloudKit and entitlements.

## Notes

This README is generated from the current codebase; if behavior changes, update the feature list to keep it accurate.
