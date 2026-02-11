# TaskFlow


TaskFlow is a SwiftUI task manager for iOS. It focuses on clean task capture, due-date tracking, and lightweight execution support with subtasks and daily notes. Data is stored locally with SwiftData.

## Product Overview

TaskFlow helps you plan, execute, and review work in a single place. Create tasks with due dates. The UI is designed to be fast and calm, with just enough structure to keep you moving.

## Key Features

- Task list with due-date sorting and swipe-to-delete
- Task creation with title and due date
- Task details view with edit-in-place
- Local storage via SwiftData

## Platforms

- iOS

## Data & Sync

TaskFlow uses SwiftData as the local persistence layer.

## Project Structure

- `TaskFlow/App`: App entry point and top-level views
- `TaskFlow/Models`: SwiftData models for tasks
- `TaskFlow/Views`: Screens and reusable UI components
- `TaskFlow/Theme`: App styling and typography
- `TaskFlow/Extensions`: Utilities and shared helpers

## Getting Started

1. Open `TaskFlow.xcodeproj` in Xcode.
2. Select an iOS target.
3. Build and run.

If you want to add sync later, you can reintroduce CloudKit and entitlements.

## Notes

This README is generated from the current codebase; if behavior changes, update the feature list to keep it accurate.
