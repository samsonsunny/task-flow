import XCTest

final class TaskFlowSubtasksUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws { }

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
        XCTAssertFalse(app.staticTexts["Nothing due tomorrow"].waitForExistence(timeout: 1))
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
        XCTAssertTrue(app.buttons["default-list-link"].waitForExistence(timeout: 2))

        app.buttons["default-list-link"].tap()
        XCTAssertTrue(app.staticTexts["Parent Project"].waitForExistence(timeout: 2))

        let parentCell = app.cells.containing(.staticText, identifier: "Parent Project")
        let parentChevron = parentCell.buttons.matching(identifier: "subtask-chevron").firstMatch
        XCTAssertTrue(parentChevron.waitForExistence(timeout: 2))

        parentChevron.tap()
        XCTAssertFalse(app.staticTexts["Child with today date"].waitForExistence(timeout: 2))
    }
}
