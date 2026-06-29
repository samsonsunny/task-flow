import XCTest
import SwiftData
@testable import TaskFlow

final class TaskTreeFlattenerTests: XCTestCase {
    private func makeTask(id: Int, title: String, parent: TaskItem? = nil) -> TaskItem {
        let task = TaskItem(taskTitle: title)
        task.parentTask = parent
        return task
    }

    // MARK: - Basic Shape

    func testSingleRoot() {
        let root = makeTask(id: 1, title: "Root")
        let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].depth, 0)
        XCTAssertEqual(result[0].subtaskCount, 0)
    }

    func testRootWithOneChild() {
        let root = makeTask(id: 1, title: "Root")
        let child = makeTask(id: 2, title: "Child", parent: root)
        root.subtasks = [child]
        let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [])
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].depth, 0)
        XCTAssertEqual(result[1].depth, 1)
    }

    func testRootWithTwoChildrenRespectsSortOrder() {
        let root = makeTask(id: 1, title: "Root")
        let childA = makeTask(id: 2, title: "A", parent: root)
        childA.sortOrder = "aaa"
        let childB = makeTask(id: 3, title: "B", parent: root)
        childB.sortOrder = "bbb"
        root.subtasks = [childB, childA]
        let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [])
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[1].task.safeTitle, "A")
        XCTAssertEqual(result[2].task.safeTitle, "B")
    }

    func testThreeLevelsOfNesting() {
        let gp = makeTask(id: 1, title: "Grandparent")
        let parent = makeTask(id: 2, title: "Parent", parent: gp)
        let child = makeTask(id: 3, title: "Child", parent: parent)
        gp.subtasks = [parent]
        parent.subtasks = [child]
        let result = TaskTreeFlattener.flatten(roots: [gp], collapsed: [])
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].depth, 0)
        XCTAssertEqual(result[0].task.safeTitle, "Grandparent")
        XCTAssertEqual(result[1].depth, 1)
        XCTAssertEqual(result[1].task.safeTitle, "Parent")
        XCTAssertEqual(result[2].depth, 2)
        XCTAssertEqual(result[2].task.safeTitle, "Child")
    }

    func testEmptyRoots() {
        let result = TaskTreeFlattener.flatten(roots: [], collapsed: [])
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Collapse

    func testCollapsedRootOmitsChildren() {
        let root = makeTask(id: 1, title: "Root")
        let child = makeTask(id: 2, title: "Child", parent: root)
        root.subtasks = [child]
        let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [root.persistentModelID])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].task.safeTitle, "Root")
    }

    func testChildCollapsedUnderExpandedRoot() {
        let root = makeTask(id: 1, title: "Root")
        let child = makeTask(id: 2, title: "Child", parent: root)
        let grandchild = makeTask(id: 3, title: "Grandchild", parent: child)
        root.subtasks = [child]
        child.subtasks = [grandchild]
        let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [child.persistentModelID])
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].task.safeTitle, "Root")
        XCTAssertEqual(result[1].task.safeTitle, "Child")
    }

    // MARK: - Completed Children

    func testIncludeCompletedFalseExcludesCompletedChildren() {
        let root = makeTask(id: 1, title: "Root")
        let child = makeTask(id: 2, title: "Done", parent: root)
        child.isCompleted = true
        root.subtasks = [child]
        let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [], includeCompleted: false)
        XCTAssertEqual(result.count, 0)
    }

    func testIncludeCompletedTrueIncludesCompletedChildren() {
        let root = makeTask(id: 1, title: "Root")
        let child = makeTask(id: 2, title: "Done", parent: root)
        child.isCompleted = true
        root.subtasks = [child]
        let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [], includeCompleted: true)
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - Subtask Count

    func testLeafTaskHasZeroSubtaskCount() {
        let root = makeTask(id: 1, title: "Leaf")
        let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [])
        XCTAssertEqual(result[0].subtaskCount, 0)
    }

    func testParentWithTwoChildrenHasCountTwo() {
        let root = makeTask(id: 1, title: "Parent")
        let c1 = makeTask(id: 2, title: "C1", parent: root)
        let c2 = makeTask(id: 3, title: "C2", parent: root)
        root.subtasks = [c1, c2]
        let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [])
        XCTAssertEqual(result[0].subtaskCount, 2)
    }

    // MARK: - Deep Nesting

    func testVeryDeepNestingDoesNotCrash() {
        var tasks: [TaskItem] = []
        let root = makeTask(id: 0, title: "Level 0")
        tasks.append(root)
        var current = root
        for i in 1...15 {
            let child = makeTask(id: i, title: "Level \(i)", parent: current)
            current.subtasks = [child]
            current = child
            tasks.append(child)
        }
        let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [])
        XCTAssertEqual(result.count, 16)
        for (index, node) in result.enumerated() {
            XCTAssertEqual(node.depth, index)
        }
    }
}
