import XCTest

/// The app uses a fixed four-tab TabView: Today, Work, Personal, More. Tests drive
/// through tabs and row actions rather than a Home-specific surface.
final class TaskFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(_ app: XCUIApplication, args: [String] = []) {
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"] + args
        app.launch()
    }

    private func element(_ identifier: String, timeout: TimeInterval = 5) -> XCUIElement {
        let match = XCUIApplication().descendants(matching: .any).matching(identifier: identifier).firstMatch
        XCTAssertTrue(match.waitForExistence(timeout: timeout), "Missing element: \(identifier)")
        return match
    }

    // MARK: - Tabs

    @MainActor
    func testAppShowsFourFixedTabs() throws {
        let app = XCUIApplication()
        launch(app)

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Work"].exists)
        XCTAssertTrue(app.tabBars.buttons["Personal"].exists)
        XCTAssertTrue(app.tabBars.buttons["More"].exists)
    }

    @MainActor
    func testWorkTabShowsDomainTasks() throws {
        let app = XCUIApplication()
        launch(app)

        app.tabBars.buttons["Work"].tap()
        XCTAssertTrue(app.navigationBars["Work"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPersonalTabShowsDomainTasks() throws {
        let app = XCUIApplication()
        launch(app)

        app.tabBars.buttons["Personal"].tap()
        XCTAssertTrue(app.navigationBars["Personal"].waitForExistence(timeout: 5))
    }

    // MARK: - Navigation

    /// Regression: a row-wide `onTapGesture` used to cover the completion circle, so tapping
    /// it opened the editor instead of completing the task.
    @MainActor
    func testTappingCompletionCircleCompletesTask() throws {
        let app = XCUIApplication()
        launch(app)

        let toggles = app.buttons.matching(identifier: "task-complete-toggle")
        waitForCount(of: toggles, toBe: 5)
        XCTAssertTrue(toggles.element(boundBy: 0).isHittable, "Completion button is not tappable")

        toggles.element(boundBy: 0).tap()

        waitForCount(of: toggles, toBe: 4)
        XCTAssertTrue(app.tabBars.buttons["Today"].exists)
    }

    /// Waits for an element count to settle. Must go through an expectation rather than a
    /// manual poll.
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
    func testTappingTodayTaskOpensEditorWithVisibleToolbar() throws {
        let app = XCUIApplication()
        launch(app)

        let row = app.staticTexts["Reply to design review"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Today did not show the task list")

        row.tap()

        let titleField = app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Tapping a task did not open the editor")

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
    func testTodayListsDueTasks() throws {
        let app = XCUIApplication()
        launch(app)

        let row = app.staticTexts["Reply to design review"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Today did not show the task list")
    }

    @MainActor
    func testNavigationBackReturnsToToday() throws {
        let app = XCUIApplication()
        launch(app)

        app.staticTexts["Reply to design review"].firstMatch.tap()
        XCTAssertTrue(
            app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch.waitForExistence(timeout: 5)
        )

        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(
            app.tabBars.buttons["Today"].waitForExistence(timeout: 5),
            "Back did not return to Today"
        )
    }

    // MARK: - More Tab & List Management

    @MainActor
    func testMoreTabShowsWorkAndPersonalDomains() throws {
        let app = XCUIApplication()
        launch(app)

        app.tabBars.buttons["More"].tap()
        XCTAssertTrue(app.navigationBars["More"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Work"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Personal"].waitForExistence(timeout: 3))
    }

    // MARK: - Floating Add Button & Quick Capture

    @MainActor
    func testFloatingAddButtonOpensEditor() throws {
        let app = XCUIApplication()
        launch(app)

        let addButton = app.buttons["floating-add-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let titleField = app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Floating add button did not open editor")

        let closeButton = app.buttons["reminder-editor-close"]
        if closeButton.waitForExistence(timeout: 3) {
            closeButton.tap()
        }
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
    func testBackFromEditorReturnsToToday() throws {
        let app = XCUIApplication()
        launch(app)

        app.staticTexts["Reply to design review"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch.waitForExistence(timeout: 3))

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(
            app.tabBars.buttons["Today"].waitForExistence(timeout: 5),
            "Pop-back did not land on Today"
        )
    }
}
