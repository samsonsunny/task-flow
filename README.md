# TaskFlow

TaskFlow is a SwiftUI task manager for iOS. It focuses on clean task capture, due-date tracking, and lightweight execution support with subtasks and daily notes. Data is stored with SwiftData and synced through iCloud via CloudKit.

## Product Overview

TaskFlow helps you plan, execute, and review work in a single place. Create tasks with due dates, break them into subtasks, and keep a running daily log of progress or notes. The UI is designed to be fast and calm, with just enough structure to keep you moving.

## Key Features

- Task list with due-date sorting and swipe-to-delete
- Search by task title or description
- Filter to show or hide completed tasks
- Task creation with title, description, due date, and optional subtasks
- Task details view with edit-in-place
- Completion tracking with completion date
- Subtask checklist with progress indicator
- Daily log entries per task with timestamps
- Status badges for Done, Overdue, and time-to-due
- iCloud sync via SwiftData + CloudKit, with pull-to-refresh to re-sync

## Platforms

- iOS

## Data & Sync

TaskFlow uses SwiftData as the local persistence layer and enables iCloud sync via CloudKit. Entitlements are configured for an iCloud container in `TaskFlow/TaskFlow.entitlements`.

## Project Structure

- `TaskFlow/App`: App entry point and top-level views
- `TaskFlow/Models`: SwiftData models for tasks, subtasks, and daily logs
- `TaskFlow/Views`: Screens and reusable UI components
- `TaskFlow/Theme`: App styling and typography
- `TaskFlow/Extensions`: Utilities and shared helpers

## Getting Started

1. Open `TaskFlow.xcodeproj` in Xcode.
2. Select an iOS target.
3. Build and run.

If you want iCloud sync, ensure your signing team has access to the configured iCloud container.

## Notes

This README is generated from the current codebase; if behavior changes, update the feature list to keep it accurate.
