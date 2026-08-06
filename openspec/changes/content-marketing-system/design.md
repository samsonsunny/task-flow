# Content Marketing System — Design

## Directory structure

```
content/
└── blog/
    ├── published/              ← articles that have gone live
    │   ├── YYYY-MM-DD-slug/
    │   │   ├── index.md
    │   │   └── images/
    │   └── ...
    ├── drafts/                 ← WIP, pre-review
    │   └── working-title/
    │       └── index.md
    ├── ideas.md                ← backlog of one-liner topics
    └── distribution.md         ← per-article distribution log
```

## Per-article frontmatter

Every article `index.md` starts with:

```yaml
---
title: "Article Title"
date: 2026-07-30
tags: [productivity, quick-capture, habits]
description: "One line for search results and social cards."
status: draft | published
canonical: https://taskflow.app/blog/article-slug
platforms:
  medium: https://medium.com/...
  devto: https://dev.to/...
---
```

## Cadence

```
Wednesday (release day): Blog post goes live
Thursday:                Cross-post to Medium, Dev.to
Friday:                  Check analytics, engage comments
Weekend:                 Draft next article
Monday:                  Review + refine draft
Tuesday:                 Final polish, PR (self-review)
Wednesday:               Publish + release 🔁
```

## Distribution process

Until `taskflow.app/blog` exists, skip the canonical-first step and publish directly to Medium and Dev.to on the same day. When the own site launches, republish there and switch the canonical to it.

Once the own site is live:

1. Publish on `taskflow.app/blog/slug` (canonical)
2. Wait 7 days for SEO indexing
3. Cross-post to Medium (with canonical link back to own site)
4. Cross-post to Dev.to (with canonical link back to own site)
5. Share on social (Threads, X, Mastodon)
6. Log in `distribution.md`

## Content sources

Each weekly app release is a content opportunity:

| Release type | Blog angle |
|---|---|
| New feature | "How [feature] changed the way I [benefit]" |
| UI change | "Why we redesigned [x]" |
| Bug fix / polish | "The attention to detail that matters" |
| No major change | Standalone productivity insight (mental model, habit, workflow) |

## Tone & voice reference

Before drafting any article, the writing agent must load `content/blog/_agent-guides/tone-reference.md`. It defines:

- The TaskFlow voice (founder-first, authoritative but personal)
- Four article formats (mental model, how-to, list, comparison)
- Product mention patterns (method-first for guides, feature-forward for how-tos)
- SEO keyword guidance from ASO metadata
- Citation style and banned language

## Format richness requirements

LLM-written articles default to plain prose when rich formatting is only "optional."
The tone guide must define a per-format **minimum formatting mix** that the writer must
meet, so richness is a definition of done rather than a nice-to-have.

| Format | Minimum mix |
|---|---|
| Mental model | 1+ blockquote (citation) · 1 comparison table · 1 💡 callout · 1 pull quote |
| How-to | Numbered steps as real ordered lists · bold on key terms · 1 callout (shortcut/gesture) · before/after table where possible |
| List / roundup | Every item = H2 + short body · 1 table or 1 blockquote |
| Comparison | Core comparison as a table · 1 honest blockquote · 1 callout (TaskFlow fit) |

These live in `content/blog/_agent-guides/tone-reference.md` so the drafting agent
loads them with the rest of the voice rules.

## Quality gates (two layers)

Richness is checked at two layers because structural checks can only catch *absence*,
not *quality*:

| Layer | What it catches | Where it runs |
|---|---|---|
| Agent self-check (semantic) | "Is the table useful? Is the quote a real citation?" — only a writer can judge this | Every draft iteration, before finalizing |
| CI structural gate (mechanical) | Missing `|` tables, `>` blockquotes, `1.` ordered lists, `##` headings | PR push, on `content/blog/drafts/**` |

The structural gate is a script that greps the draft markdown for minimum elements
(≥1 table, ≥1 blockquote, ≥2 H2s, ordered lists where expected) and fails the PR if
absent. It runs in the same PR path as the existing Dev.to draft preview in
`devto-publish.yml`, so a non-compliant draft never reaches the Dev.to preview.

## Cover image sourcing (pre-own-site)

- Stock cover images sourced from **Pexels** only (free API, ~200 req/hr). Unsplash is a drop-in alternative (same pattern, lower rate limit) — not held as a second key.
- `PEXELS_API_KEY` lives in `.env` only. It is a **creation-time tool**: the drafting agent searches for a photo and bakes the resulting URL into the draft markdown. CI needs no provider auth — image URLs are plain public hotlinks.
- Use direct `images.pexels.com/...` CDN URLs in `![alt](url)` — hotlink-able without auth (verified 200).
- **Image count (option B):** 1 cover + 1–2 in-body images per article. In-body images are allowed but not required by the structural gate; the cover is required.
- **Pre-sized URLs from the API:** use `src.landscape` (1200×627, cover aspect) for the cover and `src.large` (940×650) for in-body images — no manual query-string construction needed.
- **Caption convention:** every image is followed by an italic attribution line crediting the photographer, per Pexels guidelines:
  `*Photo by [Name](https://www.pexels.com/@handle) on [Pexels](https://www.pexels.com)*`
- The CI structural gate HEAD-checks every image URL in a draft and fails on 404, so hallucinated or dead URLs never reach the Dev.to preview. These checks hit the public CDN directly — they do not consume API quota.
- When `taskflow.app/blog` launches: swap stock URLs → self-hosted `images/` in the canonical copy; keep stock URLs on syndicated copies. No schema change needed.

## Draft checklist

Before an article is marked done, the writer verifies (self-check):

- [ ] Headings are used, not just bolded paragraphs
- [ ] ≥1 list or table exists in the body
- [ ] Every citation is a blockquote
- [ ] Every product mention uses the right pattern (method-first vs feature-forward)
- [ ] Callout boxes are blockquote-based, not plain text
- [ ] Pull quotes extracted for social distribution

## Relationship to code

- Content lives in the same repo but in its own directory tree
- Branch naming: `content/article-slug` for standalone articles, or include in the feature branch if the article is about that feature
- PRs for content follow the same review process as code
- Content deploys are separate from app deploys (different CI actions)
