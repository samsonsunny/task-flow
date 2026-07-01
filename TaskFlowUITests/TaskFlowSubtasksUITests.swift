import XCTest

final class TaskFlowSubtasksUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testParentWithChildrenShowsInlineInToday() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Parent Project"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Child with today date"].exists)
        XCTAssertTrue(app.staticTexts["Child with tomorrow date"].exists)
        XCTAssertTrue(app.staticTexts["Child no date"].exists)
    }

    @MainActor
    func testCollapseTapHidesChildren() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Parent Project"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Child with today date"].exists)

        let chevron = app.buttons["subtask-chevron"].firstMatch
        XCTAssertTrue(chevron.waitForExistence(timeout: 2))
        chevron.tap()

        XCTAssertTrue(app.staticTexts["Parent Project"].exists)
        XCTAssertFalse(app.staticTexts["Child with today date"].waitForExistence(timeout: 1))
        XCTAssertFalse(app.staticTexts["Child with tomorrow date"].exists)
        XCTAssertFalse(app.staticTexts["Child no date"].exists)
    }

    @MainActor
    func testExpandShowsChildrenAfterCollapse() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        let chevron = app.buttons["subtask-chevron"].firstMatch
        XCTAssertTrue(chevron.waitForExistence(timeout: 2))
        chevron.tap()
        XCTAssertFalse(app.staticTexts["Child with today date"].waitForExistence(timeout: 1))

        chevron.tap()
        XCTAssertTrue(app.staticTexts["Child with today date"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Child with tomorrow date"].exists)
        XCTAssertTrue(app.staticTexts["Child no date"].exists)
    }

    @MainActor
    func testOrphanSubtaskAppearsStandalone() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Orphan subtask"].waitForExistence(timeout: 2))

        let chevrons = app.buttons.matching(identifier: "subtask-chevron")
        XCTAssertEqual(chevrons.count, 1)
    }

    @MainActor
    func testChildInTomorrowTabWhenParentDifferentDate() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        app.tabBars.buttons["Tomorrow"].tap()
        XCTAssertTrue(app.staticTexts["Child with tomorrow date"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Parent Project"].exists)
    }

    @MainActor
    func testChevronOnParentOnly() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        let chevrons = app.buttons.matching(identifier: "subtask-chevron")
        XCTAssertEqual(chevrons.count, 1)
    }

    @MainActor
    func testListDetailHierarchyRegression() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_FIXTURE_SUBTASKS_INLINE"]
        app.launch()

        app.tabBars.buttons["Later"].tap()
        XCTAssertTrue(app.staticTexts["Inbox"].waitForExistence(timeout: 2))

        app.staticTexts["Inbox"].tap()
        XCTAssertTrue(app.staticTexts["Parent Project"].waitForExistence(timeout: 2))

        let chevrons = app.buttons.matching(identifier: "subtask-chevron")
        XCTAssertGreaterThanOrEqual(chevrons.count, 1)

        chevrons.firstMatch.tap()
        XCTAssertFalse(app.staticTexts["Child with today date"].waitForExistence(timeout: 1))
    }
}
