# Content Marketing

Load this only for blog, Dev.to, marketing copy, or article work. The `content/` tree was deleted in `0c991b4`; recreate it before using the publishing pipeline.

## Naming (always)

**TaskFlow is internal only.** Customer-facing copy calls the app **Wednesday Calendar** (developer: Samson Sunny). Searching the App Store for "TaskFlow" finds an unrelated app.

- Download CTA: `https://apps.apple.com/us/app/wednesday/id1455779789`
- Code, folders (`TaskFlow/`), internal docs keep "TaskFlow".
- Tab names Today / Work / Personal / More are customer-facing; keep them as-is. Never call Personal "Home" in copy.

## Process

- Cadence: one article per Wednesday, same day as app release.
- Format: Markdown + YAML frontmatter in `articles/<date>-<slug>/index.md`. Do not recreate the deleted `content/` tree; the publishing script keeps its Dev.to state outside the repo.
- Own site: `taskflow.app/blog` (subdirectory). Publish own site first → wait 7 days → cross-post to Medium/Dev.to with canonical link.
- Current state: own site not live. Publish directly to Medium and Dev.to the same day; log links in `articles/distribution.md`. When the site launches, republish there and switch canonical.
- Sources: each release is a content opportunity; otherwise write productivity insights aligned with the app's mental model.

## Frontmatter

```yaml
title, date, tags, description, status (draft|published), canonical
```

## Directory layout

```
articles/
├── YYYY-MM-DD-slug/index.md
└── distribution.md
```

## Voice and richness

- The former `content/blog/_agent-guides/tone-reference.md` (voice, SEO, richness minimums) was deleted; recreate it or ask the user for the voice before drafting.
- Richness is mandatory: headings, ≥1 list or table, citations as blockquotes, product mention pattern, callouts as blockquotes, pull quotes. LLM-written prose defaults to plain — enforce the checklist.
- Images: 1 cover (`src.landscape`, 1200×627) + up to 2 in-body (`src.large`, 940×650) from Pexels API responses; never hand-craft query strings.
- Every image is followed by `*Photo by [Name](https://www.pexels.com/@handle) on [Pexels](https://www.pexels.com)*`.
- `PEXELS_API_KEY` in gitignored `.env`; creation-time only. ~5–8 searches/article against 20k/month quota.
- CI HEAD-checks every image URL; 404 fails the build.

## Branch naming

- `content/article-slug` for standalone articles.
- Include the article in the feature branch when it is about that feature.
- Warning: anything merged under `content/blog/` publishes live immediately — review the PR and Dev.to draft first.

See `OPERATIONS.md` for the publishing commands and workflow.
