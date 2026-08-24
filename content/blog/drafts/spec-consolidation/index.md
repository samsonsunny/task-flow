---
title: "From 33 Specs to 20: Fixing Documentation Sprawl Before It Rots"
date: 2026-08-24
tags: [documentation, process, indie-dev, productivity]
description: "One spec file per feature sounded disciplined. Two years later it was 33 files of overlapping requirements. Here's the consolidation process, including the zero-loss verification that made deleting easy."
status: draft
canonical: https://taskflow.app/blog/from-33-specs-to-20
---

![A minimalist bookshelf with a hand reaching for a book](https://images.pexels.com/photos/6956497/pexels-photo-6956497.jpeg?auto=compress&cs=tinysrgb&fit=crop&h=627&w=1200)
*Photo by [Cup of Couple](https://www.pexels.com/@cup-of-couple) on [Pexels](https://www.pexels.com)*

Last week I opened my app's spec folder and counted the files. Thirty-three. For an iOS app built by one person.

Fifteen of them were shorter than 55 lines. Three described quick capture — separately. One existed purely to document UI I had already deleted. The folder had become a museum of decisions instead of a description of the product.

This is the story of consolidating those 33 specs into 20 without losing a single requirement — and the rules I wrote down so it doesn't happen again. If you maintain any documentation that grows one file at a time, the failure mode is the same whether the docs describe software, a team workflow, or your own systems.

## How the sprawl happened

It happened honestly. Every time I built a feature, I wrote a spec for it. Capture a task inline in a list? New spec. Capture a task inline in Upcoming? Another spec. A haptic on completion? Spec. An animation on completion? Different spec.

Each file made sense on the day it was written. The problem is what they described: **events, not things**. `completion-animation` describes something that happened once — completion got an animation. What a reader actually needs is *the completion experience*: the animation, the haptic, the delayed exit, together.

The symptoms were classic:

| Symptom | What it looked like |
|---|---|
| Micro-files | 15 specs under 55 lines; some were a single requirement |
| Split families | Three capture specs, three reorder specs, five notification-adjacent specs |
| Tombstones | A spec whose every requirement was marked REMOVED — history masquerading as guidance |
| Finished chores | A "cleanup" spec describing a one-time task as if it were eternal behavior |
| Inconsistent format | Some files had purpose statements and clean structure; others still carried merge markers from months ago |

None of this was visible day to day. That's what makes documentation sprawl insidious — each individual file looks fine. The rot is in the aggregate.

> "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system."
>
> — Andy Hunt & David Thomas, *The Pragmatic Programmer*

That's the DRY principle, usually applied to code. It applies twice as hard to documents, because documents have no compiler to catch the duplication.

## The rule that fixed the grouping

Before touching a single file, I wrote down the diagnosis: **specs should be organized by capability — a thing the product does — not by change — something that happened once.**

A capability can hold many requirements. Completion animation and completion haptic aren't two capabilities; they're two requirements of one capability: what completing a task feels like. Quick capture in a list, quick capture today, quick capture in Upcoming — one capability, three contexts.

With that lens, the whole folder regrouped itself almost mechanically:

| Before (33 files) | After (20 files) |
|---|---|
| contextual-task-creation, list-inline-capture, upcoming-inline-capture | quick-capture |
| completion-animation, completion-haptic-feedback | completion-interaction |
| daily-reorder, custom-list-reorder, task-actions | task-ordering |
| list-delete, list-rename, list-reorder | list-management |
| reminder-date-model, reminder-deadline-time | reminder-scheduling |
| bulk-selection, bulk-operations | bulk-editing |
| clear-notifications-on-open, notification-migration | absorbed into task-notifications |
| sidebar-navigation, clean-unused-code | deleted |

Fifteen files became six. Two moved into an existing home. Two were deleted outright. Thirteen specs I never needed to touch stayed exactly as they were.

> "A spec suite grows one file per decision until reading it costs more than rebuilding."

## The consolidation, step by step

The scary part of merging documents is silent loss — a requirement that falls out during the merge and nobody notices for a year. So the process was built around verification, not writing:

1. **Inventory every requirement title.** Not summaries, not vibes — exact headings. The count came back: 150 requirements across 33 files.
2. **Group by entity, then by verb.** Tasks, lists, editor, notifications, bulk operations. Within each group, related files revealed themselves immediately.
3. **Merge into capability files** with a normalized format: a purpose statement at top, flat requirement list below, no stale markers.
4. **Diff titles after every merge.** Every original requirement title had to appear exactly once in the output set. Four near-duplicate titles got renamed to disambiguate ("Sort order uses fractional string encoding" existed twice — once for tasks, once for lists).
5. **Reconcile scenario counts per target file.** If a merged spec absorbed three sources with 9, 9, and 8 scenarios, the result must contain exactly 26.
6. **Delete dead weight last**, once everything else was accounted for. The tombstone spec and the finished chore went to the archive.
7. **Write the index and the maintenance rules.** Twenty specs, grouped by domain, with the rules that keep it that way.

The verification changed the emotional experience entirely. Deleting a spec sounds reckless until you can say: *every requirement title and every scenario is accounted for — here are the numbers.* Then deletion stops feeling like loss and starts feeling like cleanup.

> "Perfection is achieved, not when there is nothing more to add, but when there is nothing left to take away."
>
> — Antoine de Saint-Exupéry, *Wind, Sand and Stars*

## The rules that keep it small

Consolidating once fixes nothing if the same habits rebuild the pile. These went into the index at the top of the folder:

1. **Amend, don't proliferate.** New behavior goes into an existing capability spec unless it's genuinely a new capability. A new requirement is not a reason for a new file.
2. **Prune on a cadence.** Every release: delete specs for removed behavior, flag overlaps for merging. Sprawl is cheaper to handle monthly than annually.
3. **Index by domain.** A single README mapping every spec to its area means navigation scales even when the count grows again.
4. **Normalize on touch.** Whenever a file is edited, it leaves with consistent formatting. No special trips.

![Stacked binders filled with documents](https://images.pexels.com/photos/357514/pexels-photo-357514.jpeg?auto=compress&cs=tinysrgb&h=650&w=940)
*Photo by [Pixabay](https://www.pexels.com/@pixabay) on [Pexels](https://www.pexels.com)*

## This is a to-do list problem wearing a costume

Here's why I'm writing about this on a productivity blog rather than an engineering one: the failure mode is identical to a task list that only ever grows.

Append-only systems feel productive because adding is frictionless. But a list, a wiki, or a spec suite is only as good as its **merge and delete** operations. When capturing costs nothing and consolidating costs everything, the system drifts toward noise — and eventually you stop trusting it, which defeats the entire point.

The fix is the same discipline in miniature:

| Append-only habit | Consolidation habit |
|---|---|
| New note for every thought | Add to the note that already covers the topic |
| Done items linger forever | Completed work gets archived on a schedule |
| Duplicate lists for the same project | One home per topic, links instead of copies |
| Cleanup "someday" | Cleanup on a date you chose in advance |

> 💡 **Product tip:** This is exactly why Wednesday Calendar splits tasks into two axes. Time-based tabs — Today, Tomorrow, Upcoming — hold only what deserves attention now, and everything else lives permanently in the Later tab. Nothing is ever lost by keeping the attention views small, because the permanent home absorbs the rest. Small surface, complete system.

Pick one doc collection you maintain — team wiki, personal notes, that specs folder — and run the same pass I ran: inventory what's there, group by thing-not-event, verify nothing disappears in the merge, write down the amendment rule. An hour of consolidation buys years of a system you actually trust.

---

*If you're curious about the app this documentation describes, [Wednesday Calendar](https://apps.apple.com/us/app/wednesday/id1455779789) is a free download on the App Store.*
