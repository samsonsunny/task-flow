# TaskFlow Tone & Voice Reference

## The Brand Voice

TaskFlow is a small, focused productivity app. The blog should sound like **a knowledgeable founder who uses their own product daily** — not a marketing department.

- **Confident but not arrogant** — We have opinions about task management, but we don't trash competitors
- **Clear and minimal** — No fluff, no jargon, no corporate speak. Mirror the app's design
- **Practical** — Every article should leave the reader with something they can apply today
- **Philosophical where it counts** — The two-axis model is a genuinely different way to think about tasks. Don't be afraid to explore ideas

## Tone Spectrum

```
Minimal ────────────────────────────────── Expansive
Clear ──────────────────────────────────── Poetic
Practical ──────────────────────────────── Philosophical
We focus on the left side of each spectrum for most articles.
```

Blend in the direction of Todoist's authoritative guides for thought-leadership pieces. Blend toward TickTick's personal narrative for feature/use-case articles.

## Article Formats

### 1. Mental Model / Philosophy

Explains a core idea behind TaskFlow's design.

- **Reference**: Todoist "How to Plan Your Day" (authoritative, structured, researched)
- **Structure**: Hook → problem → solution → how it works in TaskFlow → practical takeaway
- **Tone**: Third-person, confident, references to established ideas (GTD, Deep Work, Atomic Habits)
- **Product**: The philosophy comes first; TaskFlow is how you apply it
- **Example topics**: Two-axis model, attention vs home, why "Later" isn't procrastination

```
Title: "The Two-Axis Model: Why Separating Attention from Home Changes Everything"
Subtitle: "Most task managers flatten everything into one list. Here's why that's wrong."
```

### 2. Practical Guide / How-To

Shows a specific workflow or feature.

- **Reference**: TickTick "Calendar Workflows Guide" (first-person, specific, actionable)
- **Structure**: Personal story → problem → step-by-step → before/after
- **Tone**: First-person ("I"), conversational, specific (actual keystrokes, real examples)
- **Product**: Feature-forward, showing exactly what the app does
- **Example topics**: Quick capture workflow, subtask inheritance, swipe reschedule habits

```
Title: "How I Use Quick Capture to Never Lose a Thought Again"
Subtitle: "It takes 3 seconds. Here's why that changed my productivity."
```

### 3. List / Roundup

Curated list with commentary.

- **Reference**: Todoist "15 Desk Exercises" (structured, light humor, expert cites)
- **Structure**: Numbered items, each with brief explanation
- **Tone**: Practical, energetic, occasional personality
- **Product**: Subtle — can include TaskFlow as one item in a broader list
- **Example topics**: 5 productivity methods that pair well with TaskFlow, 3 ways to handle overdue tasks

```
Title: "5 Productivity Methods That Actually Work With TaskFlow"
Subtitle: "GTD, Eat the Frog, Time Blocking — here's how they map to the app."
```

### 4. Comparison / Category

Positions TaskFlow within the productivity landscape.

- **Tone**: Fair, respectful, specific. Acknowledge what competitors do well
- **Structure**: Category overview → each option → TaskFlow's fit → when to choose what
- **Product**: Honest — TaskFlow isn't for everyone. That's the point
- **Example topics**: Task managers compared, when to use lists vs dates, apps vs paper

```
Title: "Task Manager or Thought Catcher? What You Actually Need"
Subtitle: "Not every productivity problem needs the same tool."
```

## Product Mention Patterns

### Todoist pattern (subtle):

> Having trouble turning daily planning into a reflexive habit? Don't break the chain! Keep your daily planning habit going on the weekends...

The app is a footnote to the *method*. The reader learns something useful regardless of which app they use.

### TickTick pattern (direct):

> Press D for day, W for week, or M for month. Or just press 1, 2, or 3 — same result.

Specific, actionable, shows the app's polish.

### TaskFlow pattern:

Use both depending on article format:
- **Mental model guides**: Todoist pattern — method-first, TaskFlow is the implementation detail
- **How-to guides**: TickTick pattern — specific gestures, shortcuts, exact steps

## Citation Style

Reference established thinkers (James Clear, Cal Newport, David Allen) when making a point — it adds credibility. But don't overdo it. One citation per 500 words is plenty.

- How: "As [author] says in [book], '[quote].'"
- Link the book or article when possible
- No fake quotes. If you didn't verify it, don't use it

## Structure Conventions per Article

```
Frontmatter (YAML)
─────────────────
title, date, tags, description, status, canonical, platforms

Body
─────────────────
1. Hook (1-2 paragraphs) — the problem or insight
2. Body — structured with H2 sections
3. Practical takeaway (readers can act on this now)
4. Subtle CTA — link to TaskFlow feature or download (1 line)

Optional:
- Callout boxes (💡 Product Tip: ...)
- Pull quotes from the piece itself (for social distribution)
- Numbered steps for process pieces
```

## SEO Rules

From `aso-metadata.md`, key keywords to weave in naturally (not stuff):
- `productivity` — primary
- `task manager`, `to-do list`, `reminders` — secondary
- `daily planner` — used in App Store naming, relevant here too

Don't force them. If the article is genuinely about productivity, it'll include the word naturally. One targeted keyword in the title or subtitle is sufficient.

## Banned

- "Revolutionary" / "game-changing" / "next-gen"
- "Unlock your potential" / "supercharge your productivity"
- Any claim that TaskFlow will "fix" someone's life
- Overwrought metaphors (apps are not "rocketships" or "journeys")
- Emoji in body copy (keep for callout boxes only)

## Author Persona

The blog is written by **the founder of TaskFlow**. A solo developer who:
- Built the app because existing tools didn't fit how they think
- Uses it every day
- Has strong opinions about task management UX
- Is humble enough to admit what TaskFlow doesn't do well
- Believes productivity is personal — there's no one right way

Write in that voice. Not a content marketer. Not a copywriter. A builder who happens to write.
