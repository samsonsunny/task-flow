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
    func testUpcomingShowsDayAndMonthSections() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_OPEN_UPCOMING", "UITEST_FIXTURE_UPCOMING_SECTIONS", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Upcoming"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Fri, May 15"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Tue, May 19"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Prepare roadmap"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Plan sprint kickoff"].exists)

        // Far-future tasks appear in month sections (D+2 → +∞ per mental model)
        // Scroll down to reveal lazy-loaded List content outside visible area
        for _ in 0..<5 {
            if app.staticTexts["Far future milestone"].exists { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Far future milestone"].exists)
    }

    @MainActor
    func testUpcomingShowsFarFutureTasksInMonthSections() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_OPEN_UPCOMING", "UITEST_FIXTURE_UPCOMING_EMPTY", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        // All future tasks appear — D+2 → +∞ per mental model spec
        XCTAssertTrue(app.staticTexts["Upcoming"].waitForExistence(timeout: 2))
        // Scroll down to reveal lazy-loaded List content outside visible area
        for _ in 0..<5 {
            if app.staticTexts["Quarterly planning"].exists { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Quarterly planning"].exists)
    }

    @MainActor
    func testReminderCreateFlowRequiresContentBeforeSave() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        // Switch to Upcoming tab where FAB opens the full editor
        app.tabBars.buttons["Upcoming"].tap()
        XCTAssertTrue(app.buttons["reminder-create-button"].waitForExistence(timeout: 2))
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

        // Verify it shows up in Today
        app.tabBars.buttons["Today"].tap()
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
        measure {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testQuickCaptureCommitsOnEnter() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        // Tap FAB to show quick capture row on Today tab
        app.buttons["reminder-create-button"].tap()

        // Wait for quick capture field to appear and ensure it's focused
        let quickCaptureField = app.textFields["quick-capture-field"]
        XCTAssertTrue(quickCaptureField.waitForExistence(timeout: 2))
        quickCaptureField.tap()

        // Type text and press Enter to commit (works with both software and hardware keyboard)
        quickCaptureField.typeText("Test task\n")

        // Verify the task appears in the list
        XCTAssertTrue(app.staticTexts["Test task"].waitForExistence(timeout: 2))

        // Quick capture field stays visible for rapid chaining
        XCTAssertTrue(quickCaptureField.exists)
    }

    // MARK: - Later Tab Inline Creation Tests

    @MainActor
    func testLaterTabShowsInlineCreationRows() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        app.tabBars.buttons["Later"].tap()
        XCTAssertTrue(app.navigationBars["Later"].waitForExistence(timeout: 2))

        XCTAssertTrue(app.staticTexts["New List"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["New Group"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaterTabFABRemoved() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        app.tabBars.buttons["Later"].tap()
        XCTAssertTrue(app.navigationBars["Later"].waitForExistence(timeout: 2))

        let fab = app.buttons["reminder-create-button"]
        XCTAssertFalse(fab.waitForExistence(timeout: 1))
    }

    @MainActor
    func testListCreationSheetCreateDisabledWhenEmpty() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        app.tabBars.buttons["Later"].tap()
        XCTAssertTrue(app.navigationBars["Later"].waitForExistence(timeout: 2))

        app.staticTexts["New List"].tap()

        let createButton = app.buttons["Create"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 2))
        XCTAssertFalse(createButton.isEnabled)
    }

    @MainActor
    func testListCreationSheetCancelDismisses() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        app.tabBars.buttons["Later"].tap()
        XCTAssertTrue(app.navigationBars["Later"].waitForExistence(timeout: 2))

        app.staticTexts["New List"].tap()

        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2))

        cancelButton.tap()

        XCTAssertTrue(app.navigationBars["Later"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testListCreationViaSheet() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_REMINDER_HOME", "UITEST_FIXED_NOW_2026_05_13"]
        app.launch()

        app.tabBars.buttons["Later"].tap()
        XCTAssertTrue(app.navigationBars["Later"].waitForExistence(timeout: 2))

        app.staticTexts["New List"].tap()

        let textField = app.textFields["List Name"]
        XCTAssertTrue(textField.waitForExistence(timeout: 2))
        textField.tap()
        textField.typeText("Test List\n")

        let createButton = app.buttons["Create"]
        XCTAssertTrue(createButton.isEnabled)
        createButton.tap()

        XCTAssertTrue(app.navigationBars["Later"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Test List"].waitForExistence(timeout: 2))
    }
}
