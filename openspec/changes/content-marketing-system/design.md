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

## Relationship to code

- Content lives in the same repo but in its own directory tree
- Branch naming: `content/article-slug` for standalone articles, or include in the feature branch if the article is about that feature
- PRs for content follow the same review process as code
- Content deploys are separate from app deploys (different CI actions)
