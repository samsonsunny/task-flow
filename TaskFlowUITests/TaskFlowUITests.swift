//
//  TaskFlowUITests.swift
//  TaskFlowUITests
//
//  Created by sam on 26-10-2025.
//

import XCTest

final class TaskFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testRootTabsArePresentAndTomorrowTabShowsTomorrowTask() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars.buttons["Tomorrow"].exists)
        XCTAssertTrue(app.tabBars.buttons["Upcoming"].exists)

        app.tabBars.buttons["Tomorrow"].tap()
        XCTAssertTrue(app.staticTexts["Tomorrow"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Reply to design review"].exists)
    }

    @MainActor
    func testUpcomingShowsOnlyTenDayHorizonTasks() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_OPEN_UPCOMING", "UITEST_FIXTURE_UPCOMING_SECTIONS", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Upcoming"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Fri, May 15"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Tue, May 19"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Prepare roadmap"].exists)
        XCTAssertTrue(app.staticTexts["Plan sprint kickoff"].exists)
        XCTAssertFalse(app.staticTexts["Far future milestone"].exists)
    }

    @MainActor
    func testUpcomingShowsEmptyStateWhenOnlyFarFutureTasksExist() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_OPEN_UPCOMING", "UITEST_FIXTURE_UPCOMING_EMPTY", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Nothing in Upcoming"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Reminders due in the next 10 days will appear here."].exists)
    }

    @MainActor
    func testReminderCreateFlowRequiresContentBeforeSave() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        app.buttons["reminder-create-button"].tap()

        let saveButton = app.buttons["reminder-editor-save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        XCTAssertFalse(saveButton.isEnabled)

        let titleField = app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("Weekend plan")

        XCTAssertTrue(saveButton.isEnabled)

        // Enable due date so it shows up in Today
        app.switches["reminder-editor-has-date"].tap()

        saveButton.tap()

        // Verify it shows up in Today (the default tab)
        XCTAssertTrue(app.staticTexts["Weekend plan"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testReminderEditFlowShowsExistingReminderValues() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        app.tabBars.buttons["Tomorrow"].tap()
        app.staticTexts["Reply to design review"].tap()

        let titleField = app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        XCTAssertEqual(titleField.value as? String, "Reply to design review")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testQuickCaptureChevronOpensEditor() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        // Tap FAB to show quick capture row on Today tab
        app.buttons["reminder-create-button"].tap()

        // Wait for quick capture field to appear
        let quickCaptureField = app.textFields["quick-capture-field"]
        XCTAssertTrue(quickCaptureField.waitForExistence(timeout: 2))

        // Type text to ensure keyboard is active
        quickCaptureField.tap()
        quickCaptureField.typeText("Test task")

        // Tap the chevron button to open the full editor
        app.buttons["quick-capture-detail"].tap()

        // Verify the ReminderEditorView sheet appears by checking for the title field
        let editorTitleField = app.descendants(matching: .any).matching(identifier: "reminder-editor-title").firstMatch
        XCTAssertTrue(editorTitleField.waitForExistence(timeout: 3))
    }
}
