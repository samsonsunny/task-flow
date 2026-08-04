# Video Script — "TDD for SwiftUI: Test Real App Logic, Not Toy Examples"

**Status:** draft
**Length target:** 13:00–14:00
**Language:** English
**Stack:** SwiftUI + MVVM (`@Observable`), SwiftData, Swift Testing framework (Xcode 16+)
**Competes against:** Alice Academy — "Test-Driven Development in Tamil | iOS App Development"
**Positioning:** The original is a fine intro, but like most iOS TDD tutorials it stays in the abstract (toy examples, no real app). This video wins by doing TDD on *real app logic* — calendar grouping, a SwiftData-backed ViewModel — with the modern Swift Testing framework. We do not trash the original; we simply demonstrate a better, more current path. (Per TaskFlow tone rules: confident, never attack competitors.)

---

## Production Notes

- Speaking pace: ~140 wpm. Target ~1,850 spoken words across all VO.
- Every code block must be recorded as a clean screen capture (dark theme, monospace, 20pt+).
- Record each Red–Green–Refactor cycle live in Xcode: show the red test fail, show it go green. Do not fake it — that's the entire value of the video.
- Show the iOS Simulator running the real app at least twice: once mid-video to show the feature in context, once at the end for the finished feature.
- Tone: builder's voice, not a marketer's. Second-person "you", concrete, minimal hype.

---

## Title / Thumbnail (pre-roll)

**YouTube title (A/B candidates):**
- Primary: `Test-Driven Development in SwiftUI — Real Example, Not a Calculator`
- Alt A: `TDD for SwiftUI Apps: Red-Green-Refactor on a Real Feature`
- Alt B: `How to Actually TDD a SwiftUI App (Swift Testing + SwiftData)`

**Description first lines:**
> Most TDD tutorials for iOS test a toy class you'll never ship. This one tests real app logic — calendar grouping and a SwiftData-backed ViewModel — using the modern Swift Testing framework. Written tests first, then made to pass. Full code in the pinned comment.

**Tags:** swift, swiftui, tdd, test-driven development, ios development, swift testing, xcode, unit testing, mvvm, swiftdata

**Thumbnail:** split screen — left: red failing test with big X; right: green passing test with checkmark. Overlay text: "REAL TDD". Do NOT put the other channel's name or face on the thumbnail.

---

## SCRIPT

---

### 0. HOOK — 0:00–0:45

**ON SCREEN:** Dark slide. Text appears line by line:
1. "Write a test."
2. "Watch it fail."
3. "Write the code."
4. "Watch it pass."
Then a cut to a screenshot of a calculator app.

**VO:**
Every TDD tutorial for iOS shows you the same thing. Write a test. Watch it fail. Write the code. Watch it pass. Usually against a calculator, or a Roman numeral converter, or some string helper you will never actually ship.

**ON SCREEN:** Cut to the real app running — the Today screen of a to-do app, then the Completed screen showing grouped tasks.

**VO:**
So you finish the tutorial thinking "okay, I get it." And then you open a real app — one with SwiftUI, a ViewModel, and a database — and you have no idea where a test is supposed to go.

**ON SCREEN:** Title card: **"TDD for SwiftUI: Test Real App Logic, Not Toy Examples."**

**VO:**
In the next thirteen minutes I'm going to TDD a real feature of a real app, using the modern Swift Testing framework. We'll write tests for calendar logic that's genuinely fiddly, and for a ViewModel that actually talks to SwiftData. You'll see the failing test, and you'll see it turn green — on real code, not a calculator.

---

### 1. WHAT TDD IS (and isn't) — 0:45–2:30

**ON SCREEN:** Three numbered cards: RED → GREEN → REFACTOR. Small animated loop: red square flashes → green square flashes → wrench icon.

**VO:**
Quick refresher, because people get this wrong. TDD is not "write code, then write a test afterwards so the code coverage badge looks nice." TDD is a design practice with a three-step rhythm.

**VO:**
Red. You write a test for a behavior that doesn't exist yet, and you run it. It fails — ideally because the code doesn't compile yet. Green. You write the absolute minimum code to make that test pass. Not more. Refactor. You clean up both the test and the code, and you run the test again to make sure you didn't break anything.

**ON SCREEN:** Small text fades in under the three cards: *"TDD turns 'what should this do?' into 'what can I prove?'"*

**VO:**
The secret is that the tests aren't just safety nets. They're the spec. Every test is a small, executable sentence about what your code is supposed to do. And here's what makes it work in a modern SwiftUI app: we structure the code so the interesting logic lives somewhere a test can reach it — in pure functions and in the ViewModel — not buried in the View.

**ON SCREEN:** Split diagram: left "View = dumb", right "ViewModel + logic = tested".

**VO:**
Views stay dumb. They hold queries, they call the ViewModel, they render. Everything you'd actually want to guarantee — the grouping, the filtering, the date math — lives in code you can instantiate in a test with zero UI.

---

### 2. SETUP — 2:30–3:45

**ON SCREEN:** Xcode. New project. Narrator checks "Include Tests."

**VO:**
Setup is two clicks, and this is where our modern stack kicks in. When you create a new Xcode project, just tick "Include Tests." You get two targets: the unit test target and the UI test target. Today we only care about the unit test one.

**ON SCREEN:** Zoom into `MyAppTests` folder. Show the import line.

**VO:**
Notice what's in here. Not `import XCTest`. The modern way is the Swift Testing framework — you import `Testing`, you write `@Test` functions, and you assert with `#expect`. Same behavior, less ceremony, better failure messages. If your project was created before Xcode 16, you can add a Swift Testing test target next to your old XCTest one and they'll live together happily.

**ON SCREEN:** Show the in-memory container setup. Pause on `TaskPreviewData.container()`.

**VO:**
One piece of infrastructure you want before you write a single test — an in-memory SwiftData container. We use a shared preview container, and it's just a `ModelContainer` configured with `isStoredInMemoryOnly: true`. Every test gets a fresh, empty database. No files, no cleanup, no state leaking between tests. This is what lets us test a ViewModel that talks to SwiftData at all.

---

### 3. THE FEATURE WE'RE BUILDING — 3:45–4:45

**ON SCREEN:** iOS Simulator. The app's Completed screen. Narrator taps around: a task is completed, shows up under "Today."

**VO:**
Here's the feature we're going to build with TDD. In this to-do app, when you complete a task, it appears in a Completed screen — but only for thirty days. And instead of one flat list, tasks are grouped into Today, Yesterday, This Week, and Earlier. Nothing exists yet. So first, let's write a test that describes the thirty-day rule.

**VO:**
Now — a note on how to pick what to test. Start with the pure functions, the ones that take data in and return data out. They're the cheapest to test and they hold the fiddly logic. We'll get to the ViewModel — and SwiftData — in a minute.

---

### 4. CYCLE 1 — THE 30-DAY CUTOFF (RED) — 4:45–5:45

**ON SCREEN:** Xcode. A new test file `CompletedLogicTests.swift`.

**VO:**
We want a function that, given a list of tasks and a reference date, returns only the ones completed in the last thirty days. Let's write what that means.

**CODE ON SCREEN:**
```swift
import Testing
import Foundation
@testable import MyApp

@MainActor
struct CompletedLogicTests {

    @Test func excludesTasksCompletedLongerThan30DaysAgo() throws {
        let calendar = Self.testCalendar
        let now = makeDate(2026, 8, 4, calendar: calendar)

        let old = task(completedOn: makeDate(2026, 6, 25, calendar: calendar))
        let recent = task(completedOn: makeDate(2026, 7, 15, calendar: calendar))

        let result = CompletedLogic.recentTasks(
            from: [old, recent], now: now)

        #expect(result.count == 1)
        #expect(result.first?.taskTitle == "Recent")
    }
}
```

**ON SCREEN:** Narrator hits ⌘U. The test suite compiles and the test **fails red** — `CompletedLogic` doesn't exist.

**VO:**
Watch what just happened. The test doesn't compile, because `CompletedLogic` doesn't exist yet. That's our red — and a compile error is a perfectly good red. The point of TDD is you saw it fail for a concrete, honest reason.

**ON SCREEN:** Freeze frame. Small callout: *"If a test never fails, it proves nothing."*

**VO:**
Remember that rule, because we'll come back to it: if a test never fails, it proves nothing.

---

### 5. CYCLE 1 — GREEN — 5:45–6:45

**ON SCREEN:** Narrator creates `CompletedLogic.swift`. Types the minimal implementation.

**CODE ON SCREEN:**
```swift
enum CompletedLogic {

    static func recentTasks(
        from tasks: [TaskItem],
        now: Date,
        calendar: Calendar = .current
    ) -> [TaskItem] {
        guard let cutoff = calendar.date(byAdding: .day, value: -30, to: now) else {
            return tasks
        }
        return tasks.filter { task in
            guard let date = task.completedDate else { return false }
            return date >= cutoff
        }
    }
}
```

**ON SCREEN:** ⌘U. Test turns **green**.

**VO:**
The minimum code to pass: compute the cutoff, filter out everything before it. The whole point of using the real calendar math here — instead of hard-coding a timestamp — is that this test stays correct forever, even when the reference date changes.

**ON SCREEN:** Narrator opens a fixed test calendar helper. Callout: *"en_US_POSIX + UTC — no timezone surprises."*

**VO:**
One detail that saves you an afternoon of debugging: in tests, pin the calendar to `en_US_POSIX` and UTC. Date tests that depend on your machine's timezone are a time bomb — this helper is how we keep them deterministic.

**ON SCREEN:** Test helper:
```swift
static let testCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}()
```

**VO:**
Green. That's cycle one. Now, the part that actually sells TDD — cycle two, where the logic is nasty enough that you'll be *happy* to have tests.

---

### 6. CYCLE 2 — TODAY / YESTERDAY / THIS WEEK / EARLIER — 6:45–8:45

**ON SCREEN:** Simulator again — the four groups visible.

**VO:**
Here's the grouping: a completed task goes in Today if it was completed today, Yesterday if yesterday, This Week if within the last seven days, and everything older goes in Earlier. That's a decision tree, and decision trees are exactly where bugs breed. Let's pin it down with tests — one test per rule.

**CODE ON SCREEN:**
```swift
@Test func groupsTasksIntoFourBuckets() throws {
    let calendar = Self.testCalendar
    let now = makeDate(2026, 8, 4, calendar: calendar)

    let today    = task(completedOn: makeDate(2026, 8, 4, calendar: calendar))
    let yesterday = task(completedOn: makeDate(2026, 8, 3, calendar: calendar))
    let thisWeek  = task(completedOn: makeDate(2026, 7, 30, calendar: calendar))
    let earlier   = task(completedOn: makeDate(2026, 6, 1, calendar: calendar))

    let groups = CompletedLogic.groupedTasks(
        from: [today, yesterday, thisWeek, earlier], now: now)

    #expect(groups.map(\.name) == ["Today", "Yesterday", "This Week", "Earlier"])
}
```

**VO:**
Four tasks, one on each boundary, and we assert the group names come back in the exact order the UI shows them. This single test documents the entire grouping contract.

**CODE ON SCREEN:** The implementation.

```swift
static func groupedTasks(
    from tasks: [TaskItem],
    now: Date,
    calendar: Calendar = .current
) -> [(name: String, tasks: [TaskItem])] {
    let todayStart = calendar.startOfDay(for: now)
    let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
    let weekStart = calendar.date(byAdding: .day, value: -6, to: todayStart)!

    var today: [TaskItem] = []
    var yesterday: [TaskItem] = []
    var thisWeek: [TaskItem] = []
    var earlier: [TaskItem] = []

    for task in tasks {
        guard let date = task.completedDate else { continue }
        let dayStart = calendar.startOfDay(for: date)

        if calendar.isDate(dayStart, inSameDayAs: todayStart) {
            today.append(task)
        } else if calendar.isDate(dayStart, inSameDayAs: yesterdayStart) {
            yesterday.append(task)
        } else if dayStart >= weekStart {
            thisWeek.append(task)
        } else {
            earlier.append(task)
        }
    }
    return [("Today", today), ("Yesterday", yesterday),
            ("This Week", thisWeek), ("Earlier", earlier)]
}
```

**ON SCREEN:** ⌘U. Green. Narrator adds the "yesterday → today at 00:01" edge test live.

**CODE ON SCREEN:**
```swift
@Test func completedAtMidnightCountsAsToday() throws {
    let calendar = Self.testCalendar
    let now = makeDate(2026, 8, 4, 12, 0, calendar: calendar)
    let midnightTask = task(completedOn: makeDate(2026, 8, 4, 0, 1, calendar: calendar))

    let groups = CompletedLogic.groupedTasks(from: [midnightTask], now: now)

    #expect(groups.first?.name == "Today")
}
```

**VO:**
See — here's a task completed one minute after midnight. Naive string or date comparison would drop it into Yesterday, because "August 4th 00:01" is earlier than "now." But because we compare *start of day to start of day*, it correctly lands in Today. The test just locked in that behavior. This is the payoff: the exact case a human reviewer would miss.

**ON SCREEN:** Freeze frame on the passing test. Callout: *"The test you dread writing is the test worth writing."*

---

### 7. CYCLE 3 — THE @OBSERVABLE VIEWMODEL + SWIFT DATA — 8:45–11:30

**ON SCREEN:** Cut back to Xcode. New file `CompletedViewModel.swift`. Narrator highlights the `@Observable` macro.

**VO:**
Now for the part most TDD videos never touch: a ViewModel that mutates a real database. Here's the pattern, and it's the one this app uses everywhere — an `@Observable` class that gets its `ModelContext` at init, and an `update` method the View calls whenever query results change.

**CODE ON SCREEN:**
```swift
@MainActor
@Observable
final class CompletedViewModel {
    private let modelContext: ModelContext

    private(set) var recentCompletedTasks: [TaskItem] = []
    private(set) var groupedTasks: [(name: String, tasks: [TaskItem])] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func update(tasks: [TaskItem], now: Date = Date()) {
        let recent = CompletedLogic.recentTasks(from: tasks, now: now)
        recentCompletedTasks = recent
        groupedTasks = CompletedLogic.groupedTasks(from: recent, now: now)
    }
}
```

**VO:**
Two things worth noticing. First, the ViewModel is `@MainActor` — all mutations happen on the main actor, which Swift concurrency now *enforces* for us. Second, the ViewModel delegates to the pure logic we already tested. It doesn't re-implement the grouping; it composes it. That's TDD showing you where the boundaries should be.

**ON SCREEN:** Narrator writes the first ViewModel test — a mutation test with a real in-memory container.

**VO:**
Now the moment of truth. Can we test a ViewModel that actually completes a task and persists it? Watch this.

**CODE ON SCREEN:**
```swift
@Test func uncompletingTaskRemovesItFromRecentList() throws {
    let container = inMemoryContainer()
    let context = container.mainContext

    let task = TaskItem(taskTitle: "Write TDD video")
    task.isCompleted = true
    task.completedDate = Date()
    context.insert(task)
    try context.save()

    let vm = CompletedViewModel(modelContext: context)
    vm.update(tasks: [task])
    #expect(vm.recentCompletedTasks.count == 1)

    vm.uncomplete(task)

    #expect(vm.recentCompletedTasks.isEmpty)
    #expect(task.isCompleted == false)
}
```

**ON SCREEN:** ⌘U. First run — **red** because `uncomplete` doesn't exist yet. Then narrator implements it.

**CODE ON SCREEN:**
```swift
func uncomplete(_ task: TaskItem) {
    task.isCompleted = false
    task.completedDate = nil
    try? modelContext.save()
    update(tasks: recentCompletedTasks)
}
```

**ON SCREEN:** ⌘U. Green. Narrator highlights the last line of `uncomplete`.

**VO:**
Green — and this is where I want to stop and show you the subtle bit, because it's the number one bug in apps like this. Notice the last line: after we save, we call `update` again, explicitly. Here's why. The View observes the `@Query` array with `onChange`, and `onChange` uses equality. A SwiftData model compares equal by its persistent ID — changing the `isCompleted` flag doesn't change the ID. So if we *didn't* call `update` ourselves, the screen would never recompute. The test wouldn't have caught it — but the app would've shown stale data. Explicit `update` after every save is the rule in this codebase, and the mutation test is what makes you remember it.

**ON SCREEN:** Callout card: *"Every mutation: save, then update()."*

**VO:**
Every mutation ends with save and then update. One line, but it's the difference between a View that reflects reality and one that silently lies.

---

### 8. THE VIEW — DUMB ON PURPOSE — 11:30–12:30

**ON SCREEN:** Xcode, `CompletedView.swift`. Narrator points at `@Query`, `onAppear`, `onChange`.

**VO:**
And finally — the View. This is everything we *didn't* test, on purpose. The View holds the `@Query`, creates the ViewModel, and calls `update` on appear and whenever the query results change. All user actions just call a ViewModel method. No business logic lives here. No date math. No filters.

**CODE ON SCREEN:**
```swift
struct CompletedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse)
    private var allTasks: [TaskItem]

    @State private var viewModel: CompletedViewModel?

    var body: some View {
        List {
            ForEach(viewModel?.groupedTasks ?? [], id: \.name) { group in
                Section(group.name) {
                    ForEach(group.tasks) { task in
                        row(for: task)
                    }
                }
            }
        }
        .onAppear {
            viewModel = CompletedViewModel(modelContext: modelContext)
            viewModel?.update(tasks: allTasks)
        }
        .onChange(of: allTasks) { _, newTasks in
            viewModel?.update(tasks: newTasks)
        }
    }
}
```

**VO:**
This is the architecture the tests nudged us into. The View renders. The ViewModel orchestrates. The logic functions decide. Every layer has a single job, and each job is the right size to test. That's what TDD actually buys you in SwiftUI — not just confidence, but a codebase where the structure is obvious because the tests demanded it.

---

### 9. PITFALLS — 12:30–13:20

**ON SCREEN:** Three quick cards, fast cuts.

**VO:**
Three things that'll bite you if you take this into your own app. One — always run the test before you write the code. If it passes first time, you're not testing the thing you think you're testing. Two — pin your calendars and timezones. The day your CI runs in a different timezone than your laptop is the day your date tests start lying. Three — don't test the View's pixels. Test the decisions, not the layout. Your ViewModel tests are worth ten UI tests, and they run in a millisecond instead of minutes.

---

### 10. WRAP + CTA — 13:20–14:00

**ON SCREEN:** Back to the app running — the Completed screen, grouped, working.

**VO:**
That's TDD on a real feature: thirty-day cutoff, four-way grouping, and a ViewModel that mutates a real database — every step starting with a failing test and ending green.

**VO:**
If you want the full source for this — the container helper, the test calendar, both cycles — it's in the pinned comment and linked in the description. If you found this useful, subscribe — next up is the same feature, but with property-based testing and a mutation-testing tool, which is where TDD really gets fun. Thanks for watching.

**END CARD:** Channel logo. Subscribe + bell. Comment prompt: *"What feature in your app would you TDD first? I'll pick the best one for the next video."*
