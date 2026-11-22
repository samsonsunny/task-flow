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
- **Tags** (`v26.11.21`) mark released versions and are applied manually. Force pushes and deletions are blocked on `main`.

## Versioning

The version is whatever is committed in `MARKETING_VERSION` inside `TaskFlow.xcodeproj/project.pbxproj` (currently `26.11.21`).

- Email-agent commits set `MARKETING_VERSION` to today's `YY.M.DD` before committing
- Manual daily commits should do the same
- CI never edits, commits, tags, or pushes a version change
- Daily builds reuse the committed version

## Xcode Cloud Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| **CI** | Branch changes on `main` | Builds + tests on every push |
| **Daily Release** | Schedule — daily | Builds and distributes the committed version; no tag or push |

Daily Release workflow ID: `30be9eca-6c99-4d5e-b3d9-2f6c129b9587`.

## Release Scripts (`ci_scripts`)

`ci_post_clone.sh` is intentionally a no-op. Version and tag changes are manual, so builds never mutate `main` behind your local checkout.

## Notes

This README is generated from the current codebase; if behavior changes, update the feature list to keep it accurate.
