# Video Script — "TDD for SwiftUI in 2 Minutes"

**Status:** draft
**Length target:** 2:00
**Language:** English
**Stack:** SwiftUI + MVVM, SwiftData, Swift Testing
**Source:** condensed from `script.md` (14-min version). Same footage — this is the trailer / quick standalone / pre-roll cut.
**Production note:** ~280 spoken words at 140wpm. When recording, keep the pacing snappy — the 2-min version is a highlight reel, not a slower talk. Cut between: hook, one live Red–Green moment, the midnight bug, one SwiftData beat, close.

---

## Title / Description

**YouTube title:** `TDD for SwiftUI in 2 Minutes (Real Example)`
**Description first line:** The whole Red-Green-Refactor practice on real SwiftUI app logic — calendar grouping and a SwiftData ViewModel — in two minutes. Full 13-min build linked below.

**Thumbnail:** same as main video (red fail / green pass split, "REAL TDD"). No change needed — this video is a gate to the full version.

---

## SCRIPT

---

### 0:00–0:15 — HOOK

**ON SCREEN:** Calculator screenshot. Text: **"Every TDD tutorial teaches this."** Then rapid montage (calculator → roman numerals → string helper), then cut to the real app's Completed screen.

**VO:**
Every TDD tutorial for iOS teaches you the same thing — a calculator, a Roman numeral converter, a string helper. Nobody ships a calculator. So in the next two minutes: real TDD on a real SwiftUI app. Here's the whole practice.

---

### 0:15–0:35 — RED GREEN REFACTOR

**ON SCREEN:** Three cards cycling. RED → green flash. GREEN → checkmark. REFACTOR → wrench.

**VO:**
Red. Write a test for behavior that doesn't exist, run it, watch it fail. Green. Write the minimum code to make it pass — nothing more. Refactor. Clean it up, re-run. Tests aren't just safety nets — every test is an executable sentence about what your code should do.

---

### 0:35–1:10 — THE REAL EXAMPLE (live Red–Green + the midnight bug)

**ON SCREEN:** Xcode. Test file appears. ⌘U → compile error, red. Implementation appears. ⌘U → green. Then the midnight edge case, narrated over the grouping screen.

**VO:**
Here's the feature: a task list that shows only the last thirty days of completed tasks, grouped into Today, Yesterday, This Week, and Earlier. We start with the test. Watch it fail — a compile error is a perfect first red. Write the minimum code, and it's green. Now the fun part — this task was completed at 00:01. Yesterday or today? Compare the raw dates and it's "before now" — Yesterday. Wrong. Compare start-of-day to start-of-day, and 00:01 today is correctly Today. That's the exact bug a code review misses, and the test locks it in.

---

### 1:10–1:40 — THE VIEWMODEL + SWIFT DATA BEAT

**ON SCREEN:** Xcode. `@Observable` ViewModel. Highlight the in-memory container, then the last line of `uncomplete`.

**VO:**
And yes, we test the ViewModel that touches SwiftData too — every test gets a fresh in-memory database. No files, no cleanup. And here's the bug this testing discipline exposes: after a mutation you must call `update()` explicitly, because SwiftData models compare equal by ID, and `onChange` never sees a flag change. Save, then update. Every time. That one line keeps the screen honest.

---

### 1:40–2:00 — PITFALL + CTA

**ON SCREEN:** Three fast cards: "Run it before you code." / "Pin your calendars." / "Test decisions, not pixels." Then end card.

**VO:**
Three rules if you take this home: run the test before you write code, pin your calendars and timezones, and test decisions, not pixels. The full thirteen-minute build — both cycles, the container, the test calendar — is in the pinned comment. Subscribe for the property-based testing follow-up.

**END CARD:** Subscribe + bell. **"Full build → pinned comment."**
