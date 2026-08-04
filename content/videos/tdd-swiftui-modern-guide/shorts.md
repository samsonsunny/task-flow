# Shorts / Reels Pack — "TDD for SwiftUI" Clips

**Status:** draft
**Format:** Vertical 9:16, 30–60 seconds each
**Source:** derived from `script.md` (main video). Every clip reuses the same screen recordings — just recut with big text overlays.
**Platforms:** YouTube Shorts, TikTok, Instagram Reels, LinkedIn (30s variants)

---

## Short-Form Rules That Apply to Every Clip

1. **Hook in the first 2 seconds.** No intro, no logo animation, no "hey guys". First frame = text + the claim.
2. **One idea per clip.** If a clip has two ideas, it becomes two clips.
3. **Text overlays are the product.** Viewers watch muted. Every spoken sentence gets an on-screen line (3–6 words, 40pt+, high contrast).
4. **Close with a loop or a CTA.** End either on the punchline (so it can replay) or a single CTA: "Full build → link in bio / pinned comment."
5. **Post order matters** (see Strategy below) — don't dump all clips at once.

---

## CLIP 1 — "The Problem With Every TDD Tutorial" (positioning hook)

- **Duration:** ~40s
- **Source:** main video Section 0 (hook)
- **Goal:** grabs the TDD-curious viewer, sets up the full video

**Structure:**
1. (0–2s) Screenshot of a calculator app + big text: **"Every TDD tutorial teaches this."**
2. (2–12s) Rapid montage: calculator, Roman numerals, string helper.
3. (12–25s) Cut to real app — Completed screen with grouped tasks. Text: **"Nobody ships a calculator."**
4. (25–40s) Fast beats: "So you open a real SwiftUI app… a ViewModel… a database… and where does the test go?" Text: **"That's what we're fixing today."** + CTA.

**VO:**
Every TDD tutorial teaches the same thing — a calculator. Nobody ships a calculator. You open a real SwiftUI app with a ViewModel and a database, and you have no idea where the test goes. So that's what we're doing today — real TDD on real app logic. Full build's on the channel.

**Overlays:** every line above, split into 3–5 word chunks.
**Caption:** TDD is the same tutorial every time — calculator, roman numerals, string helpers. Here's the real version. #swiftui #tdd #iosdev #swift

**Record:** this is just the first 40s of the main video recut — the strongest argument for making the main video first, then clipping.

---

## CLIP 2 — "Red, Green, Refactor in 45 Seconds"

- **Duration:** ~45s
- **Source:** main video Section 1
- **Goal:** the core mental model, shareable standalone

**Structure:**
1. (0–2s) Three squares: RED / GREEN / REFACTOR.
2. (2–15s) RED — "write a test for behavior that doesn't exist. Run it. It fails."
3. (15–30s) GREEN — "write the minimum code to pass. Not more."
4. (30–45s) REFACTOR — "clean up, re-run. Tests aren't safety nets — they're the spec." Loop back to RED.

**VO:**
Red — write a test for behavior that doesn't exist. Run it, it fails. Green — minimum code to pass, nothing more. Refactor — clean up, re-run. That's the whole rhythm. And here's the thing — the tests aren't just safety nets. Every test is an executable sentence about what your code should do.

**Overlays:** RED / GREEN / REFACTOR cycling with checkmarks.
**Caption:** The entire TDD loop in under a minute. #redgreenrefactor #testdrivendevelopment #swift

---

## CLIP 3 — "The Midnight Bug" (edge case — highest engagement potential)

- **Duration:** ~45s
- **Source:** main video Section 6
- **Goal:** a genuine "aha" — something most devs would get wrong

**Structure:**
1. (0–3s) Text: **"This task was completed at 00:01. Yesterday or today?"** + a clock graphic.
2. (3–15s) Simulator — the grouping screen. "Naive date comparison puts it in Yesterday."
3. (15–30s) The fix: compare start-of-day to start-of-day. Text: **"day == day, not date == date."**
4. (30–45s) The test that locks it in + green checkmark. Text: **"The test you dread writing is the one worth writing."**

**VO:**
A task completed one minute after midnight — is that yesterday or today? If you compare the dates, it's "before now," so it lands in Yesterday. Wrong. The fix: compare start-of-day to start-of-day. Then 00:01 today is correctly today. This exact case is what a human code review misses — and it's why we test it.

**Overlays:** as above.
**Caption:** Completed at 00:01 — yesterday or today? Most devs get this wrong. #swift #iosdev #testing #programming

**Why this one:** edge-case clips outperform "here's a tip" clips because they create a moment of tension ("did I know that?"). Record this clip *before* others.

---

## CLIP 4 — "If a Test Never Fails, It Proves Nothing"

- **Duration:** ~30s
- **Source:** main video Sections 4–5
- **Goal:** principle clip, loopable, shareable

**Structure:**
1. (0–2s) Text: **"If a test never fails, it proves nothing."**
2. (2–12s) Screen recording: ⌘U, compile error, red. Text: **"Red — even a compile error counts."**
3. (12–20s) Implementation appears, ⌘U, green.
4. (20–30s) Punchline + loop back to the first line.

**VO:**
If a test never fails, it proves nothing. That's why we run the test before we write the code — a red compile error is a perfect first failure. Then the minimum code, then green. Watch a test go from "doesn't compile" to "passing" — that's the whole practice in thirty seconds.

**Overlays:** the red/green transition is the visual hook.
**Caption:** A test that always passes from day one is testing your assumptions, not your code. #tdd #swift #softwareengineering

---

## CLIP 5 — "The save() Then update() Gotcha" (SwiftData-specific — best "in my app" credibility)

- **Duration:** ~50s
- **Source:** main video Section 7
- **Goal:** a concrete bug most SwiftUI+SwiftData devs hit; makes you look like you've shipped

**Structure:**
1. (0–3s) Text: **"Why is my SwiftUI screen showing stale data?"**
2. (3–15s) The scene: View observes `@Query`, `onChange`, complete a task, nothing updates.
3. (15–30s) Explain: `onChange` uses equality; a SwiftData model compares by ID; changing a flag doesn't change the ID. Text: **"Property changes are invisible to onChange."**
4. (30–50s) The rule: **"Every mutation: save(), then update()."** Show the one line.

**VO:**
Here's the bug that eats a day: you complete a task, the database updates, the screen doesn't. The View's `onChange` fires when the query array *changes* — but SwiftData models compare equal by their ID, and a flag change doesn't change the ID. So property edits are invisible. The fix is the rule this whole app follows: after every mutation, call update — explicitly. That's it. One line, but it's the difference between a screen that tells the truth and one that silently lies.

**Overlays:** ID-comparison diagram (two models, same ID, different flag → "equal").
**Caption:** Why your SwiftUI screen shows stale SwiftData. Fix in one line. #swiftdata #swiftui #iosdev

**Why this one:** it's the most "I've shipped this" clip and the most comment-baiting ("this happened to me"). Reply to every comment — it's a community builder.

---

## CLIP 6 — "Don't Test Pixels, Test Decisions"

- **Duration:** ~35s
- **Source:** main video Section 8–9
- **Goal:** fast, opinionated, good for reaching experienced devs

**Structure:**
1. (0–3s) Text: **"Don't test pixels. Test decisions."**
2. (3–15s) Two-panel: left = UI test grinding through the Simulator; right = unit test, instant green. Text: **"minutes vs milliseconds."**
3. (15–35s) The rule: Views stay dumb, ViewModels orchestrate, pure functions decide — test the pure functions and the ViewModel. CTA to full build.

**VO:**
Don't test pixels, test decisions. A UI test takes minutes to grind through the Simulator. A ViewModel test runs in a millisecond. That's why we put the logic in the ViewModel and in pure functions — the things you want to guarantee — and keep the View dumb. One ViewModel test is worth ten UI tests.

**Overlays:** the milliseconds punchline.
**Caption:** Test the decisions, not the layout. #testing #iosdev #swiftui

---

## CLIP 7 — "Testing a ViewModel That Talks to SwiftData" (teaser for the full video)

- **Duration:** ~55s
- **Source:** main video Section 7 (setup + one assertion)
- **Goal:** the "how did you even do that" clip — drives to the full build

**Structure:**
1. (0–4s) Text: **"You can't unit test a ViewModel that touches a database."** — then narrator cuts in: "Actually…"
2. (4–15s) The in-memory container, one line highlighted.
3. (15–40s) Insert a task, complete it, instantiate the ViewModel, assert.
4. (40–55s) Green checkmark. Text: **"Real database. Zero UI. One millisecond."** + CTA.

**VO:**
"You can't unit test a ViewModel that touches a database." Actually, you can — in-memory container. Every test gets a fresh empty database: no files, no cleanup. Insert a task, instantiate the ViewModel, assert on it. Real SwiftData. Zero UI. One millisecond. The whole setup is in the full build on the channel.

**Overlays:** container line highlighted in yellow.
**Caption:** Unit-testing SwiftData ViewModels — it works. #swiftdata #tdd #swift #iosdev

---

## Strategy — Posting Order & Cadence

**Golden rule: make the full video first, then clip it.** Reels and Shorts share footage from the main video — you get 7+ pieces of content from one recording session.

**Suggested order (a "TDD on SwiftUI" mini-series, ~1 clip every 3–4 days):**
1. **CLIP 4** — "If a test never fails" (principle, sets the mood, low barrier)
2. **CLIP 3** — "The Midnight Bug" (tension + aha, highest engagement — schedule in prime time)
3. **CLIP 5** — "save() then update()" (comment bait, replies build the community)
4. **CLIP 1** — "Every TDD tutorial teaches a calculator" (positioning → channels viewers to the main video)
5. **CLIP 6** — "Don't test pixels" (reaches experienced devs)
6. **CLIP 7** — "Testing a ViewModel with SwiftData" (the "how did you do that" clip — best conversion to full video)
7. **CLIP 2** — "Red, Green, Refactor" (standalone evergreen, save it for a quiet week)

**Cross-posting notes:**
- **LinkedIn:** use the 30s versions (CLIP 4, CLIP 6) — principle clips perform better than screen-recordings there.
- **Instagram:** CLIP 3 and CLIP 5 — "did you know" clips travel furthest.
- **Every caption** ends with one line linking to the full video ("Full 13-min build → link in bio" / pinned comment).

**Analytics rule:** if a clip holds >70% retention to the end, that idea earns a sequel. CLIP 3's edge-case pattern is the most likely candidate — plan a follow-up "3 bugs your date tests won't catch."
