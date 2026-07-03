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

## Branching Strategy

TaskFlow follows **trunk-based development** with a single long-lived branch:

- **`main`** — only permanent branch. All development lands here directly.
- **Tags** (`v26.7.8`) mark weekly releases. Tags are permanent records of shipped code.
- **Branch protection** is enabled on `main`: force pushes and deletions are blocked.

### Versioning

Calendar-based `YY.M.W` format (e.g., `26.7.8` = 2026, July, week 8).

### Making a Release

```bash
# Bump version in Xcode project
# Commit changes on main
git tag v26.7.8
git push origin main --tags
# CI/CD builds and ships from the tag
```

## Xcode Cloud Workflows

Two workflows are configured in App Store Connect:

| Workflow | Trigger | What it does |
|---|---|---|
| **CI** | **Branch changes** on `main` | Builds and runs tests on every push. Fast feedback. |
| **Weekly Release** | Schedule — Wednesday | Builds, tests, tags (`vYY.M.WW`), and distributes to App Store Connect. No manual build needed — just submit for review. |

The `ci_scripts/ci_post_clone.sh` script auto-creates a git tag during the Weekly Release workflow.

## Notes

This README is generated from the current codebase; if behavior changes, update the feature list to keep it accurate.
