# TaskFlow


TaskFlow is a SwiftUI task manager for iOS focused on fast task capture and a clean, minimal list experience. Data is stored locally with SwiftData.

## Product Overview

TaskFlow keeps task capture simple: add a task quickly and see it in a calm, scrollable list. The UI emphasizes clarity and low friction.

## Key Features

- Task list sorted by creation time
- Floating quick-add button with a compact add sheet
- Task creation with title (defaults to tomorrow for the due date, no picker yet)
- Empty state when there are no tasks
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

## Getting Started

1. Open `TaskFlow.xcodeproj` in Xcode.
2. Select an iOS target.
3. Build and run.

If you want to add sync later, you can reintroduce CloudKit and entitlements.

## Notes

This README is generated from the current codebase; if behavior changes, update the feature list to keep it accurate.
