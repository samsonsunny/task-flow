//
//  TaskFlowUITests.swift
//  TaskFlowUITests
//
//  Created by sam on 26-10-2025.
//

import XCTest

final class TaskFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws { }

    private func launch(_ app: XCUIApplication, args: [String]) {
        app.launchArguments = args
        app.launch()
    }

    private func openSidebar(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["My Lists"].waitForExistence(timeout: 5))
        app.buttons["My Lists"].tap()
        XCTAssertTrue(app.navigationBars["My Lists"].waitForExistence(timeout: 5))
    }

    private func openTimePage(_ app: XCUIApplication, row: String, title: String) {
        openSidebar(app)
        app.descendants(matching: .any).matching(identifier: row).firstMatch.tap()
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTodayPageShowsTodayTasksAtLaunch() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        // Launch lands on the Today page with the capture bar focused once
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.segmentedControls["home-segment-picker"].exists)
        XCTAssertTrue(app.textFields["capture-bar-field"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
    }

    @MainActor
    func testSidebarTomorrowPageShowsTomorrowTasks() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        openTimePage(app, row: "sidebar-tomorrow-row", title: "Tomorrow")
        XCTAssertTrue(app.staticTexts["Prepare"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Reply to design review"].exists)
    }

    @MainActor
    func testUpcomingShowsDayAndMonthSections() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_OPEN_UPCOMING", "UITEST_FIXTURE_UPCOMING_SECTIONS", "UITEST_FIXED_NOW_2026_05_13"])

        XCTAssertTrue(app.navigationBars["Upcoming"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Plan"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Fri, May 15"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Tue, May 19"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Prepare roadmap"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Plan sprint kickoff"].exists)

        // Far-future tasks appear in month sections (D+2 → +∞ per mental model)
        for _ in 0..<5 {
            if app.staticTexts["Far future milestone"].exists { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Far future milestone"].exists)
    }

    @MainActor
    func testUpcomingShowsFarFutureTasksInMonthSections() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_OPEN_UPCOMING", "UITEST_FIXTURE_UPCOMING_EMPTY", "UITEST_FIXED_NOW_2026_05_13"])

        XCTAssertTrue(app.navigationBars["Upcoming"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Plan"].waitForExistence(timeout: 2))
        for _ in 0..<5 {
            if app.staticTexts["Quarterly planning"].exists { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Quarterly planning"].exists)
    }

    @MainActor
    func testEditorSaveRequiresContent() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        openTimePage(app, row: "sidebar-tomorrow-row", title: "Tomorrow")
        XCTAssertTrue(app.staticTexts["Reply to design review"].waitForExistence(timeout: 2))
        app.staticTexts["Reply to design review"].tap()

        let titleField = app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        let saveButton = app.buttons["reminder-editor-save"]

        // No unsaved changes yet — the save tick is hidden
        XCTAssertFalse(saveButton.exists)

        // Clearing the title still hides Save (empty title is not saveable)
        titleField.tap()
        let current = (titleField.value as? String) ?? ""
        titleField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        XCTAssertFalse(saveButton.exists)

        // Typing a title makes the draft dirty + saveable, so the tick appears
        titleField.typeText("Weekend plan")
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        XCTAssertTrue(saveButton.isEnabled)
    }

    @MainActor
    func testReminderEditFlowShowsExistingReminderValues() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        openTimePage(app, row: "sidebar-tomorrow-row", title: "Tomorrow")
        app.staticTexts["Reply to design review"].tap()

        let titleField = app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        XCTAssertEqual(titleField.value as? String, "Reply to design review")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testQuickCaptureCommitsOnEnter() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        // The capture bar lives at the bottom of the Today/time home
        let captureField = app.textFields["capture-bar-field"]
        XCTAssertTrue(captureField.waitForExistence(timeout: 5))
        captureField.tap()
        captureField.typeText("Test task\n")

        XCTAssertTrue(app.staticTexts["Test task"].waitForExistence(timeout: 2))
        XCTAssertTrue(captureField.exists)
    }

    // MARK: - Sidebar Tests

    @MainActor
    func testSidebarRevealShowsTimeRowsAndLists() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        openSidebar(app)

        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "sidebar-today-row").firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "sidebar-tomorrow-row").firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "sidebar-upcoming-row").firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "default-list-link").firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Inbox"].exists)
    }

    @MainActor
    func testCaptureBarAbsentOnSidebar() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        // Present on the time home
        XCTAssertTrue(app.textFields["capture-bar-field"].waitForExistence(timeout: 5))

        openSidebar(app)

        // Absent on the Lists overview
        XCTAssertFalse(app.textFields["capture-bar-field"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testCaptureBarPresentInListDetail() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        openSidebar(app)
        app.descendants(matching: .any).matching(identifier: "default-list-link").firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Inbox"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["capture-bar-field"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSidebarTodayRowReturnsHome() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        openSidebar(app)
        app.descendants(matching: .any).matching(identifier: "default-list-link").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Inbox"].waitForExistence(timeout: 5))

        // Back to the sidebar, then Today returns to the Today page
        app.buttons["My Lists"].tap()
        XCTAssertTrue(app.navigationBars["My Lists"].waitForExistence(timeout: 5))
        app.descendants(matching: .any).matching(identifier: "sidebar-today-row").firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["capture-bar-field"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testListCreationSheetCreateDisabledWhenEmpty() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        openSidebar(app)

        app.buttons["Add"].tap()

        let createButton = app.buttons["Create"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 2))
        XCTAssertFalse(createButton.isEnabled)
    }

    @MainActor
    func testListCreationSheetCancelDismisses() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        openSidebar(app)

        app.buttons["Add"].tap()

        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2))
        cancelButton.tap()

        XCTAssertTrue(app.navigationBars["My Lists"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testListCreationViaSheet() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        openSidebar(app)

        app.buttons["Add"].tap()

        let textField = app.textFields["List Name"]
        XCTAssertTrue(textField.waitForExistence(timeout: 2))
        textField.tap()
        textField.typeText("Test List\n")

        let createButton = app.buttons["Create"]
        XCTAssertTrue(createButton.isEnabled)
        createButton.tap()

        // Auto-opens the newly created list's detail, capture bar focused once
        XCTAssertTrue(app.navigationBars["Test List"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["capture-bar-field"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
    }

    @MainActor
    func testBackFromEditorDoesNotRefocusCapture() throws {
        let app = XCUIApplication()
        launch(app, args: ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"])

        openTimePage(app, row: "sidebar-tomorrow-row", title: "Tomorrow")

        // Navigating to a time page must not pop the keyboard (intent-only focus)
        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 1), "Switching pages opened the keyboard")

        app.staticTexts["Reply to design review"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch.waitForExistence(timeout: 2))

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Tomorrow"].waitForExistence(timeout: 5))

        // Returning from the editor must not refocus the capture bar
        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 1), "Pop-back refocused the capture bar")
    }
}