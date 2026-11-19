# TaskFlow


TaskFlow is a SwiftUI task manager for iOS focused on fast task capture and a clean, minimal list experience. Data is stored with SwiftData and synced through a private CloudKit database.

## Product Overview

TaskFlow keeps task capture simple: add a task quickly and see it in a calm, scrollable list. The UI emphasizes clarity and low friction.

## Key Features

- Fixed four-tab navigation: `Today`, `Work`, `Personal`, `More`
- Exactly two permanent domains: Work and Personal
- Projects/lists as optional organization inside a domain
- Cross-domain Today view with collapsible Overdue and due-today tasks
- Domain task surfaces with list and board display modes
- Per-domain Inbox bucket for tasks created without a project
- Fast task capture and editing with scheduling, subtasks, and priorities
- Recently Completed archive under More
- Local storage via SwiftData with iCloud sync

## Platforms

- iOS

## Data & Sync

TaskFlow uses SwiftData with a private CloudKit database for sync across devices signed in to the same Apple ID. See `ai/CONVENTIONS.md` for CloudKit schema constraints.

## Project Structure

- `TaskFlow/App`: App entry point and root views
- `TaskFlow/Features`: Feature folders (View + ViewModel co-located)
- `TaskFlow/Models`: SwiftData models and area reconciliation
- `TaskFlow/Views/Components`: Shared UI components
- `TaskFlow/DesignSystem`: App styling, typography, and tokens
- `TaskFlow/Utilities`: Notifications, ordering, date, and badge helpers

## AI Agent Navigation

`AGENTS.md` is the agent entry point. `ai/INDEX.md` routes to focused docs (`ai/ARCHITECTURE.md`, `ai/REPO-MAP.md`, `ai/CONVENTIONS.md`, `ai/OPERATIONS.md`, `ai/CONTENT.md`) so agents load only the context they need. `ai/manifest.json` is the machine-readable index.

## Color System

TaskFlow uses semantic color tokens centralized in `TaskFlow/DesignSystem/Colors.swift` and backed by color assets in `TaskFlow/Assets.xcassets`.

- Never use raw hex values in views.
- Use only semantic tokens (`primaryAction`, `appBackground`, `surface`, `textPrimary`, `border`, etc.).
- Avoid opacity-based text coloring; use `textPrimary`, `textSecondary`, and `textDisabled`.
- See `ai/CONVENTIONS.md` and `TaskFlow/DesignSystem/Colors.swift` for palette and roles.

## Getting Started

1. Open `TaskFlow.xcodeproj` in Xcode.
2. Select an iOS target.
3. Build and run, or use `xcodebuild -project TaskFlow.xcodeproj -scheme TaskFlow -destination 'generic/platform=iOS Simulator' build`.

See `ai/OPERATIONS.md` for test, CI, release, and content publishing commands.


## Branching Strategy

Trunk-based development with a single permanent branch:

- **`main`** — only branch. All development lands here directly.
- **Tags** (`v26.7.15`) mark daily releases. Force pushes and deletions are blocked on `main`.

## Versioning

Versions are **release dates** in `YY.M.DD` format (e.g. `26.7.15` = release on July 15).

- Build runs **daily** and uses the **trigger date** as its version
- `ci_post_clone.sh` updates `main` to that date before building
- No post-build version bump

## Xcode Cloud Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| **CI** | Branch changes on `main` | Builds + tests on every push |
| **Daily Release** | Schedule — daily | Builds, tags, and distributes to App Store Connect |

Daily Release workflow ID: `30be9eca-6c99-4d5e-b3d9-2f6c129b9587`.

## Auto-Release Flow (ci_scripts)

One script automates the daily release — no manual version bumps needed.

### Before build (`ci_post_clone.sh`)

Sets the project to **today's date** (e.g. July 8 → `26.7.8`), commits it, tags `v26.7.8`, and pushes. The build then uses this version.

### Example

| Date | Step | main version | Tag |
|---|---|---|---|
| July 8 | Clone before build | `26.7.8` | — |
| | `ci_post_clone.sh` | `26.7.8` (committed) | `v26.7.8` |
| | Xcode Cloud builds with `26.7.8` | | |
| July 9 | Clone before build | `26.7.9` | — |
| | `ci_post_clone.sh` | `26.7.9` (committed) | `v26.7.9` |
| ... | repeats daily | | |

No manual version bumps. Each day's build uses its own date as the release version.

## Notes

This README is generated from the current codebase; if behavior changes, update the feature list to keep it accurate.
