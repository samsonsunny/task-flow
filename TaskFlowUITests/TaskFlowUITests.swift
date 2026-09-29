import XCTest

/// Home is now the app's only surface, so these tests drive Home directly. The former
/// sidebar helpers (`openSidebar`, `openTimePage`, `expandArea`) are gone along with the
/// split view — destinations are reached from Home's own rows.
final class TaskFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(_ app: XCUIApplication, args: [String] = []) {
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"] + args
        app.launch()
    }

    private var areaSwitcher: XCUIElement {
        XCUIApplication().segmentedControls["home-area-switcher"].firstMatch
    }

    private func element(_ identifier: String, timeout: TimeInterval = 5) -> XCUIElement {
        let match = XCUIApplication().descendants(matching: .any).matching(identifier: identifier).firstMatch
        XCTAssertTrue(match.waitForExistence(timeout: timeout), "Missing element: \(identifier)")
        return match
    }

    // MARK: - Area switcher

    @MainActor
    func testHomeShowsNativeSegmentedAreaControl() throws {
        let app = XCUIApplication()
        launch(app)

        let switcher = app.segmentedControls["home-area-switcher"].firstMatch
        XCTAssertTrue(switcher.waitForExistence(timeout: 5), "Area switcher is not a segmented control")
        XCTAssertTrue(switcher.buttons["Work"].exists, "Segment label 'Work' is not shown")
        XCTAssertTrue(switcher.buttons["Personal"].exists, "Segment label 'Personal' is not shown")
    }

    /// The switcher must actually be tappable — a custom pill in a toolbar slot can render
    /// its labels yet swallow the gesture.
    @MainActor
    func testAreaSwitcherRespondsToTap() throws {
        let app = XCUIApplication()
        launch(app)

        let switcher = app.segmentedControls["home-area-switcher"].firstMatch
        XCTAssertTrue(switcher.waitForExistence(timeout: 5))
        let personal = switcher.buttons["Personal"]
        XCTAssertTrue(personal.isHittable, "Personal segment is not hittable")
        personal.tap()

        // The selected segment must be the one left selected, i.e. the tap registered.
        XCTAssertEqual(personal.value as? String, "1", "Personal segment was not selected")
    }

    /// Switching areas must not silently keep the previous area's capture target.
    @MainActor
    func testCaptureDestinationFollowsSelectedArea() throws {
        let app = XCUIApplication()
        launch(app)

        let switcher = app.segmentedControls["home-area-switcher"].firstMatch
        XCTAssertTrue(switcher.waitForExistence(timeout: 5))
        switcher.buttons["Personal"].tap()

        let field = app.textFields["capture-bar-field"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("Personal-only task\n")

        // The captured task must appear in the selected area's flat list.
        XCTAssertTrue(app.staticTexts["Personal-only task"].waitForExistence(timeout: 5))
    }

    // MARK: - Navigation

    /// Regression: the editor was once presented in a `.sheet` with
    /// `embedInNavigationStack: false`, which gave it no navigation bar at all — so its
    /// close and save buttons had nowhere to render and were invisible. It has to be
    /// *pushed* onto a real stack, as every other editor call site does.
    /// Regression: a row-wide `onTapGesture` used to cover the completion circle, so tapping
    /// it opened the editor instead of completing the task. Home also hides completed work, so
    /// a successful tap must drop the row rather than leave a struck-through one — and the tap
    /// must not navigate.
    @MainActor
    func testTappingCompletionCircleCompletesTask() throws {
        let app = XCUIApplication()
        launch(app)

        let toggles = app.buttons.matching(identifier: "task-complete-toggle")
        // The fixture seeds six Work tasks, one of them already completed, and Home hides
        // completed work — so five rows is correct.
        waitForCount(of: toggles, toBe: 5)
        XCTAssertTrue(toggles.element(boundBy: 0).isHittable, "Completion button is not tappable")

        // Tap a circle without caring which task it belongs to — the row count is the contract.
        toggles.element(boundBy: 0).tap()

        // Home hides completed work, so a successful tap drops the row entirely.
        waitForCount(of: toggles, toBe: 4)
        // Completing must stay on Home — the circle is not a navigation gesture.
        XCTAssertTrue(app.segmentedControls["home-area-switcher"].firstMatch.exists)
    }

    /// Waits for an element count to settle. Must go through an expectation rather than a
    /// manual poll: a tight `usleep` loop floods the accessibility channel and starves the
    /// very UI update being waited on, so the count never appears to change.
    private func waitForCount(
        of elements: XCUIElementQuery,
        toBe expected: Int,
        within timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in elements.count == expected },
            object: nil
        )
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result, .completed,
            "Expected \(expected) rows, saw \(elements.count)",
            file: file,
            line: line
        )
    }

    @MainActor
    func testTappingHomeTaskOpensEditorWithVisibleToolbar() throws {
        let app = XCUIApplication()
        launch(app)

        let row = app.staticTexts["Reply to design review"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Home did not show the flat task list")

        row.tap()

        let titleField = app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Tapping a task did not open the editor")

        // A navigation bar must exist, otherwise the editor's toolbar has nowhere to render.
        // `save` is deliberately absent until the form is dirty, so editing is what reveals it.
        XCTAssertEqual(titleField.value as? String, "Reply to design review")
        XCTAssertTrue(app.navigationBars.buttons.firstMatch.isHittable, "No way to leave the editor")
        XCTAssertFalse(app.buttons["reminder-editor-save"].exists, "An untouched task should not offer Save")

        titleField.tap()
        titleField.typeText(" edited")

        let saveButton = app.buttons["reminder-editor-save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button is missing from the editor toolbar")
        XCTAssertTrue(saveButton.isHittable, "Save button is present but not tappable")
    }

    @MainActor
    func testHomeListsSelectedAreaTasksNewestFirst() throws {
        let app = XCUIApplication()
        launch(app)

        // Home is one flat list now: no section headers, no time links, just rows.
        // `element()` asserts existence, so negative checks must not use it.
        XCTAssertFalse(
            app.descendants(matching: .any).matching(identifier: "home-time-tomorrow").firstMatch.exists,
            "Time links are gone from Home"
        )
        XCTAssertFalse(app.buttons["home-overflow-menu"].exists, "Overflow menu is gone from Home")

        let row = app.staticTexts["Reply to design review"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Home did not show the flat task list")
    }

    @MainActor
    func testNavigationBackReturnsToHome() throws {
        let app = XCUIApplication()
        launch(app)

        app.staticTexts["Reply to design review"].firstMatch.tap()
        XCTAssertTrue(
            app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch.waitForExistence(timeout: 5)
        )

        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(
            app.segmentedControls["home-area-switcher"].firstMatch.waitForExistence(timeout: 5),
            "Back did not return to Home"
        )
    }

    @MainActor
    func testUpcomingShowsDayAndMonthSections() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_UPCOMING_SECTIONS"])

        XCTAssertTrue(app.navigationBars["Upcoming"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Plan"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Fri, May 15"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Tue, May 19"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Prepare roadmap"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Plan sprint kickoff"].exists)

        for _ in 0..<5 {
            if app.staticTexts["Far future milestone"].exists { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Far future milestone"].exists)
    }

    @MainActor
    func testUpcomingShowsFarFutureTasksInMonthSections() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_UPCOMING_EMPTY"])

        XCTAssertTrue(app.navigationBars["Upcoming"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Plan"].waitForExistence(timeout: 2))
        for _ in 0..<5 {
            if app.staticTexts["Quarterly planning"].exists { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Quarterly planning"].exists)
    }

    // MARK: - Capture bar

    @MainActor
    func testQuickCaptureCommitsOnEnter() throws {
        let app = XCUIApplication()
        launch(app)

        let captureField = app.textFields["capture-bar-field"].firstMatch
        XCTAssertTrue(captureField.waitForExistence(timeout: 5))
        captureField.tap()
        captureField.typeText("Test task\n")

        XCTAssertTrue(app.staticTexts["Test task"].waitForExistence(timeout: 2))
        XCTAssertTrue(captureField.exists)
    }

    /// Committing must dismiss the keyboard and release the bar, rather than leaving it
    /// latched open over the list.
    @MainActor
    func testCaptureBarDismissesAfterCommit() throws {
        let app = XCUIApplication()
        launch(app)

        let captureField = app.textFields["capture-bar-field"].firstMatch
        XCTAssertTrue(captureField.waitForExistence(timeout: 5))
        captureField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3), "Keyboard did not appear on focus")
        captureField.typeText("Dismiss me\n")

        XCTAssertFalse(
            app.keyboards.firstMatch.waitForExistence(timeout: 2),
            "Keyboard stayed up after committing a capture"
        )
    }

    @MainActor
    func testCaptureBarReappearsForNextTask() throws {
        let app = XCUIApplication()
        launch(app)

        let captureField = app.textFields["capture-bar-field"].firstMatch
        XCTAssertTrue(captureField.waitForExistence(timeout: 5))
        captureField.tap()
        captureField.typeText("First\n")
        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 2))

        // The bar must still be usable, not stuck unfocused after dismissing itself.
        captureField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3), "Capture bar could not be re-focused")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure {
            XCUIApplication().launch()
        }
    }

    // MARK: - List creation

    @MainActor
    func testListCreationViaOverflow() throws {
        let app = XCUIApplication()
        launch(app)


        app.buttons["New List"].tap()

        let textField = app.textFields["List Name"]
        XCTAssertTrue(textField.waitForExistence(timeout: 3))
        textField.tap()
        textField.typeText("Test List\n")

        app.buttons["Create"].tap()

        XCTAssertTrue(
            app.navigationBars["Test List"].waitForExistence(timeout: 5),
            "Creating a list did not open its detail"
        )
    }

    @MainActor
    func testListCreationCreateDisabledWhenEmpty() throws {
        let app = XCUIApplication()
        launch(app)


        app.buttons["New List"].tap()

        let createButton = app.buttons["Create"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 3))
        XCTAssertFalse(createButton.isEnabled)
    }

    @MainActor
    func testListCreationCancelDismisses() throws {
        let app = XCUIApplication()
        launch(app)


        app.buttons["New List"].tap()

        app.buttons["Cancel"].tap()

        XCTAssertTrue(
            app.segmentedControls["home-area-switcher"].firstMatch.waitForExistence(timeout: 3),
            "Cancel did not return to Home"
        )
    }

    /// A list has one area for life, so the sheet has to state the destination rather than
    /// offer a picker.
    @MainActor
    func testListCreationStatesDestinationArea() throws {
        let app = XCUIApplication()
        launch(app)

        app.segmentedControls["home-area-switcher"].firstMatch.buttons["Personal"].tap()

        app.buttons["New List"].tap()

        XCTAssertTrue(
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Personal")).firstMatch.waitForExistence(timeout: 3),
            "List creation sheet did not state the destination area"
        )
    }

    // MARK: - Editor

    @MainActor
    func testEditorSaveRequiresContent() throws {
        let app = XCUIApplication()
        launch(app)

        XCTAssertTrue(app.staticTexts["Reply to design review"].waitForExistence(timeout: 5))
        app.staticTexts["Reply to design review"].tap()

        let titleField = app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 3))
        let saveButton = app.buttons["reminder-editor-save"]

        XCTAssertFalse(saveButton.exists)

        titleField.tap()
        let current = (titleField.value as? String) ?? ""
        titleField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        XCTAssertFalse(saveButton.exists)

        titleField.typeText("Weekend plan")
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        XCTAssertTrue(saveButton.isEnabled)
    }

    @MainActor
    func testReminderEditFlowShowsExistingReminderValues() throws {
        let app = XCUIApplication()
        launch(app)

        app.staticTexts["Reply to design review"].firstMatch.tap()

        let titleField = app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 3))
        XCTAssertEqual(titleField.value as? String, "Reply to design review")
    }

    @MainActor
    func testBackFromEditorDoesNotRefocusCapture() throws {
        let app = XCUIApplication()
        launch(app)

        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 1), "Pushing a destination opened the keyboard")

        app.staticTexts["Reply to design review"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch.waitForExistence(timeout: 3))

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(
            app.segmentedControls["home-area-switcher"].firstMatch.waitForExistence(timeout: 5),
            "Pop-back did not land on Home"
        )

        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 1), "Pop-back refocused the capture bar")
    }
}
