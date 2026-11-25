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

- Trunk-based: `main` is the only permanent branch; tags `vYY.M.DD` mark released versions and are applied manually.
- Rebase onto latest `origin/main` before making changes so pushes stay fast-forward; never force-push `main`.
- `MARKETING_VERSION` in `TaskFlow.xcodeproj/project.pbxproj` is the source of truth. Email-agent commits set it to today's `YY.M.DD` before committing; manual daily commits should do the same. CI never changes it.
- `ci_scripts/ci_post_clone.sh` is a no-op: no version bump, commit, tag, or push.
- Xcode Cloud has a single workflow named `CI`, scheduled Tuesday 19:00. Only that scheduled run submits to App Store review; manual, rebuild, push, and PR runs build/distribute without submitting. No tag or push.
- The `CI` workflow ID is not stored in the repo; the submission hook matches `CI_WORKFLOW=ci` case-insensitively.
- The `CI` workflow submits its archive via `ci_scripts/ci_post_xcodebuild.sh` and `ci_scripts/appstore_submit.py`. The hook exits unless `CI_START_CONDITION=schedule`, the action is `archive`, and `CI_XCODEBUILD_EXIT_CODE=0`; this excludes `manual`, `manual_rebuild`, `push`, `pr_open`, and `pr_update`. The Tuesday 19:00 schedule itself is configured in App Store Connect, not in this repository.
- One-time App Store Connect setup: the `CI` workflow's archive deployment preparation must be `TestFlight and App Store`, and its post-action distribution destination must be `App Store Connect`, so the build is uploaded before submission. Create a team API key with App Manager role and add three secret environment variables to the workflow: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_API_KEY_BASE64` (base64 of the `.p8` file, single line). Never commit the `.p8` or these values.
- `appstore_submit.py` uses only Python 3 stdlib + `openssl`, finds the version/build by bundle ID and committed `MARKETING_VERSION`, PATCHes `whatsNew` on the `en-US` `appStoreVersionLocalization`, attaches the build, creates a `reviewSubmissions` container, adds the version as an item, and sets `submitted: true`. An existing `WAITING_FOR_REVIEW`/`IN_REVIEW` submission is a no-op.
- What's New is a generic `- Bug fixes and performance improvements.` by default. Dynamic commit-derived notes are intentionally deferred; `--release-notes <path>` overrides with a manual text file. No `ci_post_xcodebuild.sh` change is needed for the weekly `CI` schedule.
- Local preview without credentials: `python3 ci_scripts/appstore_submit.py --version <YY.M.DD> --build-number <n> --dry-run` (prints the What's New that would be sent; no App Store Connect calls).
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

Runs inbound `[dev]` emails through headless opencode directly in the clean `main` checkout, verifies with `xcodebuild`, commits to `main`, pushes to `EMAIL_AGENT_REMOTE` (default `origin`), and replies by SMTP. It never opens a PR or creates an `email-agent/*` branch. Incoming mail is read with Microsoft Graph because Outlook.com IMAP OAuth is unreliable.

Prerequisites:

- The repo must be in a non-TCC-protected path such as `~/Projects/TaskFlowApp`; a LaunchAgent cannot read scripts under `~/Desktop`.
- You must be logged in to the macOS user session. The screen may be locked; after logout/restart the job stops until the next login.
- The plist must include `/Users/sam/.opencode/bin` in `PATH`; launchd's default PATH omits it.
- The daemon passes `--dir` and `PWD` explicitly; launchd starts with `PWD=/`, which otherwise makes opencode create the session in the global `/` project instead of the repo.
- Git push must work non-interactively from launchd via the inherited `SSH_AUTH_SOCK`.

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
   EMAIL_AGENT_REMOTE=origin
   ```

   Optional: `EMAIL_AGENT_AGENT_ATTEMPTS` (default `3`) and `EMAIL_AGENT_AGENT_RETRY_DELAY` (default `5` seconds) control retries for transient opencode server errors. Retries only happen when the failed attempt left no file changes.

   Replies (`Re:`/`Fwd:`) and messages tagged `X-Email-Agent-Generated: true` are ignored, including the agent's own replies. Outbound Message-IDs are recorded in `.email-agent/state.json` so a delivery copy cannot be reprocessed. Send a fresh `[dev]` email rather than replying to an agent message.

2. Outlook.com requires OAuth2; basic auth/app passwords will not work. `EMAIL_AGENT_OAUTH_CLIENT_ID` defaults to Thunderbird's public client ID and can be overridden with your own Entra app registration.
3. Run `./scripts/email-agent --auth` and complete both Microsoft device-code sign-ins (Graph `Mail.ReadWrite`, then SMTP `Send`). Tokens are cached in `.email-agent/msal_cache.json` (mode 600, gitignored) and refreshed silently.
4. Run `./scripts/email-agent --check` to verify Graph and SMTP auth, then `./scripts/email-agent --once` for a single poll or no flag for a long-running daemon.
5. Install the launch agent:

   ```bash
   cp scripts/com.taskflow.email-agent.plist ~/Library/LaunchAgents/
   launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.taskflow.email-agent.plist
   launchctl kickstart -k gui/$UID/com.taskflow.email-agent
   ```

6. Unload with `launchctl bootout gui/$UID ~/Library/LaunchAgents/com.taskflow.email-agent.plist`. Logs: `.email-agent/logs/`. State, tokens, and derived data live under gitignored `.email-agent/`.

Send a new email from `samsonsunny@outlook.com` to the same address with subject `[dev] <request>` and a plain-text body. The checkout must be on `main`; if it has pending changes, the agent sets `MARKETING_VERSION` to today's `YY.M.DD`, builds, commits them separately as `wip: pending changes before <request>`, and pushes before working on the request. The agent fetches and rebases onto `origin/main` before starting work and again before building; a rejected push triggers one fetch/rebase/retry. It never force-pushes. On success it replies with target branch, commit, push result, build result, and changed files.


## CI workflow (`.github/workflows/devto-publish.yml`)

- PR open/update: drafts under `content/blog/drafts/` → private Dev.to drafts.
- Merge to `main`: those drafts go live, then archive to `content/blog/published/YYYY-MM-DD-slug/` with `status: published`.
- Manual dispatch: re-publish all drafts or a specific `article` path.
- `.devto.json` is committed back on merge/manual runs only (not PR runs, to avoid loops).
