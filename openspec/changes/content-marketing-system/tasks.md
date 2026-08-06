## 1. Richness requirements in the tone guide

- [ ] 1.1 Add the per-format "minimum formatting mix" table to `content/blog/_agent-guides/tone-reference.md` (mental model, how-to, list, comparison)
- [ ] 1.2 Move callout boxes / pull quotes / numbered steps from "Optional" to required-where-format-applies in the structure conventions section
- [ ] 1.3 Add the draft checklist (headings, ≥1 list or table, citations as blockquotes, product mention pattern, callouts as blockquotes, pull quotes) to the tone guide

## 2. Draft workflow instructions

- [ ] 2.1 Add one line to `AGENTS.md` content workflow: before finalizing any article, run the richness self-check from the tone guide

## 3. CI structural gate

- [ ] 3.1 Add `scripts/check-article-format.mjs` that reads a draft `index.md` and asserts minimum elements: ≥1 table row (`|`), ≥1 blockquote (`>`), ≥2 `##` headings, ordered lists (`1.`) where the format requires
- [ ] 3.2 Have the script HEAD-check every image URL (`![](url)`) in the draft and fail on 404 (no provider auth needed — public hotlinks)
- [ ] 3.3 Wire the script into `devto-publish.yml` PR path (runs before the Dev.to draft step on `content/blog/drafts/**`); failing the check blocks the Dev.to preview
- [ ] 3.4 Exit 0 for non-article changes; keep the gate scoped to drafts only (published archive is post-hoc)

## 4. Cover image sourcing

- [ ] 4.1 Drafting agent sources images via the Pexels search API using `PEXELS_API_KEY` from `.env` (creation-time only — never a GitHub secret), embedding direct `images.pexels.com` CDN URLs in the draft markdown
- [ ] 4.2 Image policy: exactly 1 cover (`src.landscape`, 1200×627) + up to 2 in-body (`src.large`, 940×650); every image followed by the italic attribution caption; rate budget ~5–8 requests/article vs 20,000/month quota
