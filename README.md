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

Trunk-based development with a single permanent branch:

- **`main`** — only branch. All development lands here directly.
- **Tags** (`v26.7.15`) mark weekly releases. Force pushes and deletions are blocked on `main`.

## Versioning

Versions are **release dates** in `YY.M.DD` format (e.g. `26.7.15` = release on July 15).

- Build runs on **Wednesday** for the **next Wednesday's** release
- Version on `main` during the week points to the upcoming release
- After the build, `main` advances to the week after that

## Xcode Cloud Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| **CI** | Branch changes on `main` | Builds + tests on every push |
| **Weekly Release** | Schedule — Wednesday | Builds, tags, and distributes to App Store Connect |

## Auto-Release Flow (ci_scripts)

Two scripts automate the weekly release — no manual version bumps needed.

### Before build (`ci_post_clone.sh`)

Sets the project to the **next Wednesday's date** (e.g. July 8 → `26.7.15`), commits it, tags `v26.7.15`, and pushes. The build then uses this version.

### After build (`ci_post_xcodebuild.sh`)

Bumps `main` to the **Wednesday after the release** (e.g. `26.7.22`) so the project is ready for the next week's development.

### Example

| Date | Step | main version | Tag |
|---|---|---|---|
| July 8 (Wed) | Clone before build | `26.7.15` | — |
| | `ci_post_clone.sh` | `26.7.15` (committed) | `v26.7.15` |
| | Xcode Cloud builds with `26.7.15` | | |
| | `ci_post_xcodebuild.sh` | bumped to `26.7.22` | |
| July 8–14 | Development | `26.7.22` | |
| July 15 (Wed) | Clone before build | `26.7.22` | — |
| | `ci_post_clone.sh` | `26.7.22` (already set, skip) | `v26.7.22` |
| | `ci_post_xcodebuild.sh` | bumped to `26.7.29` | |
| July 15–21 | Development | `26.7.29` | |
| ... | repeats weekly | | |

No manual version bumps. Every Wednesday, Xcode Cloud tags the release version and advances main to the next one.

## Notes

This README is generated from the current codebase; if behavior changes, update the feature list to keep it accurate.
