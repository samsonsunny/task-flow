# Content Marketing System

## Problem

TaskFlow ships weekly app updates but has no content pipeline to match. Each release is a marketing opportunity — feature launches, mental-model explanations, productivity insights — but there's no systematic way to create, review, publish, and distribute that content alongside the code.

## Proposal

Co-locate a content marketing pipeline in the same repo as the iOS app. Start at Phase 1 (plain Markdown in `content/`), scale to a static site when volume justifies it. One article per week minimum, aligned with the Wednesday release cadence.

## Scope

### In scope
- `content/blog/` directory with Markdown articles
- Cross-platform distribution process (own site → syndication)
- Agent instructions in AGENTS.md for content workflow
- Frontmatter conventions for metadata

### Out of scope (Phase 2+)
- Static site generator setup (Astro/11ty)
- CI/CD for blog deployment
- Image optimization pipeline
- Newsletter integration

## Success criteria

- First article published within one week
- 4+ articles in `content/blog/` within first month
- Each article cross-posted to at least one external platform
- Blog lives at `taskflow.app/blog` (subdirectory, not subdomain)

## Key decisions

| Decision | Choice | Rationale |
|---|---|---|
| Domain structure | Subdirectory (`/blog`) | Shares SEO authority with app domain; one brand |
| Platform strategy | Own site first → syndicate after 7 days | Canonical gets SEO credit; syndication reaches new audiences |
| Content format | Markdown with frontmatter | Zero tooling cost, native to repo, easy to migrate to SSG later |
| Cadence | Weekly, aligned with Wednesday app release | Feature ships → article about feature; natural content fuel |
| Who writes | Founder only (phase 1) | Keep quality high, process minimal until proven |
