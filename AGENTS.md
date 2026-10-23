# TaskFlow — AI Agent Instructions

## Architecture: MVVM

This project follows the **MVVM (Model-View-ViewModel)** pattern. All view-layer code must follow these rules:

### Rules

1. **Views never contain business logic or data mutations.** Views observe ViewModel state and delegate all actions to the ViewModel.
2. **All ViewModels are `@Observable` classes.** Do NOT use `ObservableObject` / `@Published`.
3. **Views hold `@Query` for SwiftData fetching.** ViewModels receive data via an `update()` method — they do not own `@Query`.
4. **ViewModels receive `modelContext` at init** from the view's `@Environment(\.modelContext)`.
5. **ViewModels are co-located with their View** in the same folder.
6. **UI-only state** (`@FocusState`, `@State` for sheet booleans, `@Environment(\.dismiss)`) stays in the view.
7. **Every mutation must call `update()` after `modelContext.save()`.** `onChange(of:)` uses `Equatable` comparison; `@Model` objects compare equal by `persistentModelID`, so property-only changes are invisible to `onChange`. Explicit `update()` is the only reliable way to recompute derived state after a mutation. For inserts/deletes, update `allTasks` (add/remove) before calling `update()`.

### Date formatting

When using `DateFormatter.setLocalizedDateFormatFromTemplate()`, always set `formatter.locale` **before** calling the template method. The template parsing is locale-sensitive — it uses whatever locale is set at call time to determine component order (e.g., "May 15" vs "15 May"). Setting locale afterward only affects component names, not their order.

### File organization

Features are split into domain-based folders under `Features/`. Each screen co-locates its View and ViewModel in the same folder. Truly shared files stay at the feature root or in `Views/Components/`.

```
TaskFlow/Features/
├── Today/                           (cross-domain Today + overdue)
│   ├── TodayTaskListView.swift
│   └── TodayViewModel.swift
├── Areas/                           (Work and Personal task surfaces)
│   ├── AreaTasksView.swift
│   ├── AreaTasksViewModel.swift
│   └── AreaBoardView.swift
├── Lists/                           (domain-scoped list management + list detail)
│   ├── ListView.swift
│   ├── ListViewModel.swift
│   ├── ListCreationSheet.swift
│   ├── DetailView.swift
│   └── DetailViewModel.swift
├── Editor/                          (create/edit reminder, schedule picker)
│   ├── EditorView.swift
│   ├── EditorViewModel.swift
│   ├── Draft.swift
│   ├── ListPickerView.swift
│   ├── DatePickerSheet.swift
│   └── DatePickerViewModel.swift
├── Completed/
│   ├── CompletedView.swift
│   └── CompletedViewModel.swift
├── Settings/                        (More tab)
│   ├── MoreView.swift
│   └── MoreViewModel.swift
├── Home/                            (legacy; not root navigation)
├── Tasks/                           (legacy Timeline views; not root navigation)
└── MainTabView.swift
```

### Full conventions

See `openspec/standards/mvvm-conventions.md` for the detailed pattern reference, including the ViewModel template, testing approach, and what stays in the view.

### Product mental model

Read `openspec/specs/app-mental-model/spec.md` before making architectural or navigation decisions. It is binding.

**Product invariants — do not deviate:**

1. **Exactly two domains: Work and Personal.** They are represented by `ReminderListGroup` (legacy type name), seeded and locked by `AreaReconciler`. Never create a third domain or let users create/rename/delete domains.
2. **Root tabs are fixed: Today, Work, Personal, More.** Never add tabs for projects, lists, user groups, or legacy `Later`/`Tomorrow`/`Upcoming` surfaces. The tab bar is the same on every device and size class.
3. **Projects/lists are optional organization inside a domain.** Every `ReminderList` belongs to exactly one domain. Projects never become top-level tabs. A list's domain is fixed at creation.
4. **Today is cross-domain.** It shows overdue + due-today tasks from both Work and Personal. Future/undated tasks stay in their domain.
5. **Each domain owns one protected Inbox bucket.** New tasks without a project land there. Bucket identity is derived from domain membership + canonical `Inbox` name; never add a persisted pointer (CloudKit schema is sealed).
6. **No new model fields for the domain/project distinction.** `ReminderListGroup` = domain, `ReminderList` = project/list. Extra groups are folded into Work on launch with lists and tasks preserved.
7. **Product copy says "Personal", not "Home".** "Home" is a retired display alias; stored values remain `Work`/`Personal`.
8. **No sidebar or `NavigationSplitView` root.** Root navigation is the four-tab `TabView`.

If code and these docs disagree, treat the docs as the target and fix the code — do not reintroduce project tabs or user-created domains.

### Existing specs

Feature specs are in `openspec/specs/`. Active changes with implementation tasks are in `openspec/changes/`.

Before implementing an active change, validate it against `openspec/specs/app-mental-model/spec.md`. Proposals or tasks that assume `Later` / `Tomorrow` / `Upcoming` tabs, a sidebar, `NavigationSplitView`, per-area time views, or user-created groups are stale. Do not implement those navigation parts; update the change to the fixed `Today / Work / Personal / More` model first.

### SwiftData schema migrations

When adding a new property to an existing `@Model`, you have two options:

1. **Preferred (simple additions):** Add the property directly to the latest schema version and remove `migrationPlan:` from `ModelContainer`. SwiftData does implicit lightweight migration without checksum validation.
2. **Full versioned schema:** Create a new schema version (e.g., `TaskFlowSchemaV10`), add the property there, update typealiases, and update `Schema(versionedSchema:)` in `TaskFlowApp.swift` and `TaskPreviewData.swift`. **Do NOT add a `migrationPlan:`** — it triggers checksum validation which can collide with existing stages for minimal schema changes.

### CloudKit schema immutability

The iCloud model is mirrored to CloudKit (`ModelConfiguration(cloudKitDatabase:)`). CloudKit **production record types are immutable and sealed by the app's build number**: the schema generation CloudKit accepts is keyed to `CFBundleVersion` (`CURRENT_PROJECT_VERSION`).

- **Any change to a CloudKit-mirrored `@Model` — a new field, relationship, or rename — MUST ship with a strictly higher `CURRENT_PROJECT_VERSION` (build number).** Never change the model and leave the build number unchanged: the mirroring delegate then tries to add the field to the sealed production record type and aborts every export/import with `Cannot create or modify field '<name>' in record '<type>' in production schema`. The failure is silent to the user — local changes appear to save but never leave the device, and a reinstall shows "all data gone".
- Bumping `MARKETING_VERSION` alone does NOT help; only `CURRENT_PROJECT_VERSION` moves the CloudKit schema generation.
- Adding a brand-new entity alone does not need a bump (new record types are always creatable); adding fields/relationships to an **existing** mirrored entity does.
- If a bump is not possible for an in-progress feature, do not add the fields to already-deployed entities — derive them at runtime instead.
- Recovery: install a build whose build number is higher than the one that sealed the schema; the delegate then deploys a new generation and re-imports existing records. Resetting the CloudKit production environment (Dashboard) is destructive to all users and is a last resort only.

---

## Content Marketing System

The repo includes a content pipeline alongside the iOS app. See `openspec/changes/content-marketing-system/` for the full design and proposal.

### Process

- **Cadence:** One article per week, published Wednesday (same day as app release)
- **Format:** Markdown with YAML frontmatter in `content/blog/`
- **Own site:** Blog lives at `taskflow.app/blog` (subdirectory, not subdomain)
- **Distribution:** Publish on own site first → wait 7 days → cross-post to Medium/Dev.to with canonical link
- **No site yet (current):** Until `taskflow.app/blog` exists, publish directly to Medium and Dev.to on the same day (no 7-day canonical wait). Log all links in `distribution.md`. When the own site launches, republish there and switch the canonical to it.

### App naming & App Store URL

**"TaskFlow" is the internal/project name only — never customer-facing.** The App Store app is called **Wednesday Calendar** (developer: Samson Sunny). All external copy (blog articles, changelogs, metadata, marketing) must call it **Wednesday Calendar**, never "TaskFlow" — searching the App Store for "TaskFlow" surfaces an unrelated app.

- App Store URL (use for any download CTA): `https://apps.apple.com/us/app/wednesday/id1455779789`
- Code, folder names (`TaskFlow/`), and internal docs keep the "TaskFlow" name. Only customer-facing copy is renamed.
- Tab names ("Today", "Work", "Personal", "More") are customer-facing and match the App Store listing — keep them as-is in articles. Never call a domain "Home" in customer-facing copy.

### Dev.to publishing script

`scripts/publish-devto.mjs` publishes an article to Dev.to from its `index.md` via the Forem API:

```bash
DEVTO_API_KEY=xxx node scripts/publish-devto.mjs <article.md> --draft   # create as draft
DEVTO_API_KEY=xxx node scripts/publish-devto.mjs <article.md> --publish # publish or make live
```

- API key from `dev.to/settings/extensions`; never commit it.
- State (article id/url per path) is stored in `content/blog/.devto.json` so re-runs update instead of duplicating.
- Max 4 tags are sent (Dev.to limit).
- `content/blog/.config.json` has `ownSiteLive: false`; set to `true` once `taskflow.app/blog` exists so the script starts sending `canonical_url`.
- Add `--dry-run` to preview the payload without calling the API.
- Medium still requires a manual/import step (no new API tokens issued).

### Dev.to GitHub Actions workflow

`.github/workflows/devto-publish.yml` automates publishing from the repo:

- **On PR open/update:** every article under `content/blog/drafts/` is created/updated as a Dev.to *draft* (private — safe preview). Iterate on the article, push, and the draft updates.
- **On merge to `main`:** every article under `content/blog/drafts/` is **published live** to Dev.to automatically. Merging the PR *is* the publish action — no manual step. After publishing, the workflow archives the article to `content/blog/published/YYYY-MM-DD-slug/` and sets `status: published`.
- Editing an existing article's markdown and merging pushes the update to the live post (good for corrections).
- **Manual dispatch** (Actions → Dev.to Publish → Run workflow): re-publishes all drafts, or a specific `article` path input — useful for an immediate re-run without a commit.
- The script falls back to matching existing Dev.to articles by title, so re-runs update instead of duplicating.
- Requires the `DEVTO_API_KEY` repo secret (Settings → Secrets and variables → Actions). `.devto.json` state is committed back automatically on merge/manual runs (not on PR runs, to avoid self-triggering loops).
- **Watch out:** anything merged under `content/blog/` goes live immediately — review the PR (and the Dev.to draft preview) before merging.

### Content directory structure

```
content/blog/
├── published/YYYY-MM-DD-slug/
│   ├── index.md                  ← article with frontmatter
│   └── images/                   ← article-specific images
├── drafts/working-title/
│   └── index.md
├── _agent-guides/
│   └── tone-reference.md         ← voice, richness minimums, checklist
├── ideas.md                      ← topic backlog
└── distribution.md               ← per-article cross-post log
```

### Frontmatter requirements

Every article must include:
```yaml
title, date, tags, description, status (draft|published), canonical
```

### Content sources

Each weekly app release is a content opportunity. Ship a feature → write the article about it. Between feature releases, write standalone productivity insights aligned with the app's mental model.

### Tone & voice

Before drafting an article, read `content/blog/_agent-guides/tone-reference.md` for voice, format, product mention patterns, SEO rules, and the per-format richness minimums. This defines the TaskFlow blog voice — authoritative but personal, inspired by Todoist and TickTick blog styles.

### Richness & images

- **Richness is mandatory, not optional.** Before finalizing any article, run the richness self-check in `tone-reference.md` (headings, ≥1 list or table, citations as blockquotes, product mention pattern, callouts as blockquotes, pull quotes). LLM-written articles default to plain prose unless the minimums are enforced.
- **Image policy (option B):** 1 cover + up to 2 in-body images per article. Use `src.landscape` (1200×627) for the cover and `src.large` (940×650) for in-body from the Pexels API response — never hand-craft query strings.
- **Captions:** every image is followed by an italic attribution line: `*Photo by [Name](https://www.pexels.com/@handle) on [Pexels](https://www.pexels.com)*`.
- **API key:** `PEXELS_API_KEY` lives in `.env` (gitignored). It is a **creation-time tool** — used only to search for images during drafting. Publish-time serves images from the public CDN with zero API usage. Never add it to GitHub.
- **Quota:** ~5–8 search requests per article vs 20,000/month free. Pexels is the only image provider (Unsplash is a drop-in alternative, not held as a second key).
- **Liveness:** the CI structural gate HEAD-checks every image URL in a draft and fails on 404. These checks hit the public CDN, not the API.

### Branch naming

- `content/article-slug` for standalone articles
- Include in feature branch if the article is about that feature
