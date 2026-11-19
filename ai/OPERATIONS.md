# Operations

Load this for build, test, CI, release, env, or script work.

## Build / test / lint

```bash
xcodebuild -project TaskFlow.xcodeproj -scheme TaskFlow -destination 'generic/platform=iOS Simulator' build
xcodebuild test -project TaskFlow.xcodeproj -scheme TaskFlow \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

- Open `TaskFlow.xcodeproj` in Xcode; iOS target; sources auto-discovered via `PBXFileSystemSynchronizedRootGroup`.
- `TaskFlowTests` / `TaskFlowUITests` targets exist but have **no test sources**. `xcodebuild test` currently verifies compilation only.
- No SwiftLint, SwiftFormat, Makefile, or package scripts exist. Do not invent lint commands.

## Git / release

- Trunk-based: `main` is the only permanent branch; tags `vYY.M.DD` mark daily releases.
- Versions are release dates (`YY.M.DD`). Build daily for the same day's release.
- `ci_scripts/ci_post_clone.sh` sets today's version, commits, tags, pushes.
- Xcode Cloud: CI builds/tests on `main` pushes; Daily Release tags and distributes to App Store Connect.
- Daily Release workflow ID: `30be9eca-6c99-4d5e-b3d9-2f6c129b9587`.
- Never commit `.derivedData/`, `DerivedData/`, `build/`, `.ralph/runs/`, `.env`, or `.xcuserdata`. Derived data is gitignored and untracked as of `5c32541`.

## Content scripts

```bash
DEVTO_API_KEY=xxx node scripts/publish-devto.mjs <article.md> --draft    # create/update private draft
DEVTO_API_KEY=xxx node scripts/publish-devto.mjs <article.md> --publish  # publish/update live
DEVTO_API_KEY=xxx node scripts/publish-devto.mjs <article.md> --dry-run  # preview payload
```

- `DEVTO_API_KEY` from `dev.to/settings/extensions`; also a GitHub Actions secret. Never commit it.
- `PEXELS_API_KEY` lives in gitignored `.env` (creation-time image search only).
- State: `content/blog/.devto.json`; config: `content/blog/.config.json` (`ownSiteLive: false`).
- `content/` was deleted in `0c991b4`; the script and workflow remain but the article tree must be recreated before use.

## CI workflow (`.github/workflows/devto-publish.yml`)

- PR open/update: drafts under `content/blog/drafts/` → private Dev.to drafts.
- Merge to `main`: those drafts go live, then archive to `content/blog/published/YYYY-MM-DD-slug/` with `status: published`.
- Manual dispatch: re-publish all drafts or a specific `article` path.
- `.devto.json` is committed back on merge/manual runs only (not PR runs, to avoid loops).
