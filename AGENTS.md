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
├── Tasks/                           (Today/Tomorrow/Upcoming tabs)
│   ├── TodayView.swift
│   ├── TomorrowView.swift
│   ├── UpcomingView.swift
│   ├── TimelineView.swift
│   ├── TimelineViewModel.swift
│   ├── TimelineSections.swift
│   └── TimeSegments.swift
├── Lists/                           (Later tab + list detail)
│   ├── ListView.swift
│   ├── ListViewModel.swift
│   ├── DetailView.swift
│   └── DetailViewModel.swift
├── Editor/                          (create/edit reminder, schedule picker)
│   ├── EditorView.swift
│   ├── EditorViewModel.swift
│   ├── Draft.swift
│   ├── DatePickerSheet.swift
│   └── DatePickerViewModel.swift
├── Completed/
│   ├── CompletedView.swift
│   └── CompletedViewModel.swift
├── Settings/
│   └── SettingsView.swift
├── FloatingAddButton.swift
└── MainTabView.swift
```

### Full conventions

See `openspec/standards/mvvm-conventions.md` for the detailed pattern reference, including the ViewModel template, testing approach, and what stays in the view.

### Product mental model

Read `openspec/specs/app-mental-model/spec.md` before making architectural or navigation decisions. It defines the two-axis model (attention vs home) that all features build on.

### Existing specs

Feature specs are in `openspec/specs/`. Active changes with implementation tasks are in `openspec/changes/`.

### SwiftData schema migrations

When adding a new property to an existing `@Model`, you have two options:

1. **Preferred (simple additions):** Add the property directly to the latest schema version and remove `migrationPlan:` from `ModelContainer`. SwiftData does implicit lightweight migration without checksum validation.
2. **Full versioned schema:** Create a new schema version (e.g., `TaskFlowSchemaV10`), add the property there, update typealiases, and update `Schema(versionedSchema:)` in `TaskFlowApp.swift` and `TaskPreviewData.swift`. **Do NOT add a `migrationPlan:`** — it triggers checksum validation which can collide with existing stages for minimal schema changes.

---

## Content Marketing System

The repo includes a content pipeline alongside the iOS app. See `openspec/changes/content-marketing-system/` for the full design and proposal.

### Process

- **Cadence:** One article per week, published Wednesday (same day as app release)
- **Format:** Markdown with YAML frontmatter in `content/blog/`
- **Own site:** Blog lives at `taskflow.app/blog` (subdirectory, not subdomain)
- **Distribution:** Publish on own site first → wait 7 days → cross-post to Medium/Dev.to with canonical link
- **No site yet (current):** Until `taskflow.app/blog` exists, publish directly to Medium and Dev.to on the same day (no 7-day canonical wait). Log all links in `distribution.md`. When the own site launches, republish there and switch the canonical to it.

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

- **On merge to `main`:** every article under `content/blog/drafts/` is created/updated as a Dev.to *draft* (nothing goes live).
- **Manual dispatch** (Actions → Dev.to Publish → Run workflow): publishes articles under `content/blog/published/` (or a specific `article` path input).
- The script falls back to matching existing Dev.to articles by title, so moving an article from `drafts/` to `published/` updates it instead of duplicating.
- Requires the `DEVTO_API_KEY` repo secret (Settings → Secrets and variables → Actions). `.devto.json` state is committed back automatically by the workflow.

### Content directory structure

```
content/blog/
├── published/YYYY-MM-DD-slug/
│   ├── index.md                  ← article with frontmatter
│   └── images/                   ← article-specific images
├── drafts/working-title/
│   └── index.md
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

Before drafting an article, read `content/blog/_agent-guides/tone-reference.md` for voice, format, product mention patterns, and SEO rules. This defines the TaskFlow blog voice — authoritative but personal, inspired by Todoist and TickTick blog styles.

### Branch naming

- `content/article-slug` for standalone articles
- Include in feature branch if the article is about that feature
