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

## Email-driven development agent

Runs inbound `[dev]` emails through headless opencode in an isolated git worktree, verifies with `xcodebuild`, commits to an `email-agent/*` branch, and replies by SMTP. Incoming mail is read with Microsoft Graph because Outlook.com IMAP OAuth is unreliable.

Setup (one time):

1. Put the non-secret settings in gitignored `.env` (the wrapper loads it):

   ```text
   EMAIL_AGENT_AUTH_MODE=oauth2
   EMAIL_AGENT_SMTP_HOST=smtp-mail.outlook.com
   EMAIL_AGENT_SMTP_PORT=587
   EMAIL_AGENT_USERNAME=samsonsunny@outlook.com
   EMAIL_AGENT_ALLOWED_FROM=samsonsunny@outlook.com
   EMAIL_AGENT_SUBJECT_PREFIX=[dev]
   EMAIL_AGENT_POLL_SECONDS=60
   ```

   Outlook.com requires OAuth2; basic auth/app passwords will not work. `EMAIL_AGENT_OAUTH_CLIENT_ID` defaults to Thunderbird's public client ID and can be overridden with your own Entra app registration.
3. Run `./scripts/email-agent --auth` and complete both Microsoft device-code sign-ins (Graph `Mail.ReadWrite`, then SMTP `Send`). Tokens are cached in `.email-agent/msal_cache.json` (mode 600, gitignored) and refreshed silently.
4. Run `./scripts/email-agent --check` to verify Graph and SMTP auth, then `./scripts/email-agent --once` for a single poll or no flag for a long-running daemon.
5. Install the launch agent:

   ```bash
   cp scripts/com.taskflow.email-agent.plist ~/Library/LaunchAgents/
   launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.taskflow.email-agent.plist
   launchctl kickstart -k gui/$UID/com.taskflow.email-agent
   ```

   Unload with `launchctl bootout gui/$UID ~/Library/LaunchAgents/com.taskflow.email-agent.plist`. Logs: `.email-agent/logs/`. State, worktrees, tokens, and derived data live under gitignored `.email-agent/`.

Send email from `samsonsunny@outlook.com` to the same address with subject `[dev] <request>` and a plain-text body. The agent replies with branch, commit, build result, and changed files. Only merge the branch after review.

## CI workflow (`.github/workflows/devto-publish.yml`)

- PR open/update: drafts under `content/blog/drafts/` → private Dev.to drafts.
- Merge to `main`: those drafts go live, then archive to `content/blog/published/YYYY-MM-DD-slug/` with `status: published`.
- Manual dispatch: re-publish all drafts or a specific `article` path.
- `.devto.json` is committed back on merge/manual runs only (not PR runs, to avoid loops).
