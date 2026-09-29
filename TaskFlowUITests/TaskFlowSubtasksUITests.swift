import XCTest

final class TaskFlowSubtasksUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws { }

    @MainActor
    func testTodayShowsParentWithOverviewAndHidesDatedChild() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Parent Project"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Child with today date"].waitForExistence(timeout: 1))

        let summary = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "0/3")
        ).firstMatch
        XCTAssertTrue(summary.exists)
    }

    @MainActor
    func testNonDatedChildNotShownInToday() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Parent Project"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Child no date"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testChildDueTomorrowNotShownInToday() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Parent Project"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Child with tomorrow date"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testDatedOrphanSubtaskNotShownInTimeline() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Parent Project"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Orphan subtask"].waitForExistence(timeout: 1))
        XCTAssertFalse(app.staticTexts["Orphan parent"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testSubtasksVisibleOnlyInTaskDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Parent Project"].waitForExistence(timeout: 2))
        app.staticTexts["Parent Project"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["Child no date"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Child with today date"].exists)
        XCTAssertTrue(app.staticTexts["Child with tomorrow date"].exists)
    }
}
