# TaskFlow


TaskFlow is a SwiftUI task manager for iOS focused on fast task capture and a clean, minimal list experience. Data is stored with SwiftData and synced through a private CloudKit database.

## Product Overview

TaskFlow keeps task capture simple: add a task quickly and see it in a calm, scrollable list. The UI emphasizes clarity and low friction.

## Key Features

- Fixed grouped navigation: Tasks holds `Personal` (shown as Home) then `Work`; `Search` is a separate search tab
- Exactly two permanent domains: Work and Personal
- Projects/lists as optional organization inside a domain
- Domain task surfaces with title-only needs-attention, upcoming, list, and completed sections
- Quick capture on Home and Work creates a task due today or tomorrow in that domain's Inbox
- Per-domain Inbox bucket for tasks created without a project
- Full task capture sheet with title, due date, and list selection
- Local storage via SwiftData with iCloud sync

## Platforms

- iOS

## Data & Sync

TaskFlow uses SwiftData with a private CloudKit database for sync across devices signed in to the same Apple ID. The versioned schema is `TaskFlowSchemaV10` in `TaskFlow/Models/TaskItem.swift`.

## Project Structure

- `TaskFlow/App`: App entry point and root views
- `TaskFlow/Features`: Feature folders (View + ViewModel co-located)
- `TaskFlow/Models`: SwiftData schema, models, and derived helpers
- `TaskFlow/Views/Components`: Shared UI components
- `TaskFlow/DesignSystem`: Shared editorial styling
- `TaskFlow/Assets.xcassets`: Color sets and custom tab symbols

## AI Agent Navigation

`AGENTS.md` is the agent entry point. `ai/manifest.json` is the machine-readable index of live source areas, key files, and commands.

## Color System

Color sets live in `TaskFlow/Assets.xcassets` (for example `primaryAction`, `appBackground`, `surface`, `textPrimary`, `border`). Views use SwiftUI semantic colors and `Color.accentColor`; shared editorial styling lives in `TaskFlow/DesignSystem/EditorialStyle.swift`.

## Getting Started

1. Open `TaskFlow.xcodeproj` in Xcode.
2. Select an iOS target.
3. Build and run, or use `xcodebuild -project TaskFlow.xcodeproj -scheme TaskFlow -destination 'generic/platform=iOS Simulator' build`.

Build, test, release, and publishing commands are listed in `ai/manifest.json`.


## Branching Strategy

Trunk-based development with a single permanent branch:

- **`main`** — only branch. All development lands here directly.
- **Tags** (`v26.11.21`) mark released versions and are applied manually. Force pushes and deletions are blocked on `main`.

## Versioning

The version is whatever is committed in `MARKETING_VERSION` inside `TaskFlow.xcodeproj/project.pbxproj`.

- Email-agent commits set `MARKETING_VERSION` to today's `YY.M.DD` before committing
- Manual daily commits should do the same
- CI never edits, commits, tags, or pushes a version change
- Daily builds reuse the committed version

## Xcode Cloud Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| **CI** | Schedule — Tuesday 19:00 | Builds, distributes, and submits the committed version to App Store review; no tag or push |

The `CI` workflow is matched by name in the submission hook; its schedule is configured in App Store Connect, not in this repository.

## App Store submission

`ci_scripts/ci_post_xcodebuild.sh` submits the archive after a successful `CI` build. It reads the version and build number from the archive, then calls `ci_scripts/appstore_submit.py`, which uses the App Store Connect API to attach the uploaded build and submit the version for review. An existing review submission is left untouched.

One-time setup in App Store Connect:

1. Set the `CI` workflow's archive deployment preparation to `TestFlight and App Store` and its post-action distribution destination to `App Store Connect`.
2. Create a team API key with App Manager role; note the key ID, issuer ID, and downloaded `.p8`.
3. Add secret environment variables to that workflow: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_API_KEY_BASE64` (single-line base64 of the `.p8`).

The API key can submit to the store; keep it out of the repository and rotate it if exposed.

## Release Scripts (`ci_scripts`)

`ci_post_clone.sh` is intentionally a no-op. Version and tag changes are manual, so builds never mutate `main` behind your local checkout.

## Notes

This README is generated from the current codebase; if behavior changes, update the feature list to keep it accurate.
