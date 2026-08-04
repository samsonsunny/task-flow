import Testing
import SwiftData
@testable import TaskFlow

private func makeTask(id: Int, title: String, parent: TaskItem? = nil) -> TaskItem {
    let task = TaskItem(taskTitle: title)
    task.parentTask = parent
    return task
}

// MARK: - Basic Shape

@Test func singleRoot() {
    let root = makeTask(id: 1, title: "Root")
    let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [])
    #expect(result.count == 1)
    #expect(result[0].depth == 0)
    #expect(result[0].subtaskSummary.isEmpty)
}

@Test func rootWithOneChild() {
    let root = makeTask(id: 1, title: "Root")
    let child = makeTask(id: 2, title: "Child", parent: root)
    root.subtasks = [child]
    let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [])
    #expect(result.count == 2)
    #expect(result[0].depth == 0)
    #expect(result[1].depth == 1)
}

@Test func rootWithTwoChildrenRespectsSortOrder() {
    let root = makeTask(id: 1, title: "Root")
    let childA = makeTask(id: 2, title: "A", parent: root)
    childA.sortOrder = "aaa"
    let childB = makeTask(id: 3, title: "B", parent: root)
    childB.sortOrder = "bbb"
    root.subtasks = [childB, childA]
    let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [])
    #expect(result.count == 3)
    #expect(result[1].task.safeTitle == "A")
    #expect(result[2].task.safeTitle == "B")
}

@Test func threeLevelsOfNesting() {
    let gp = makeTask(id: 1, title: "Grandparent")
    let parent = makeTask(id: 2, title: "Parent", parent: gp)
    let child = makeTask(id: 3, title: "Child", parent: parent)
    gp.subtasks = [parent]
    parent.subtasks = [child]
    let result = TaskTreeFlattener.flatten(roots: [gp], collapsed: [])
    #expect(result.count == 3)
    #expect(result[0].depth == 0)
    #expect(result[0].task.safeTitle == "Grandparent")
    #expect(result[1].depth == 1)
    #expect(result[1].task.safeTitle == "Parent")
    #expect(result[2].depth == 2)
    #expect(result[2].task.safeTitle == "Child")
}

@Test func emptyRoots() {
    let result = TaskTreeFlattener.flatten(roots: [], collapsed: [])
    #expect(result.isEmpty)
}

// MARK: - Collapse

@Test func collapsedRootOmitsChildren() {
    let root = makeTask(id: 1, title: "Root")
    let child = makeTask(id: 2, title: "Child", parent: root)
    root.subtasks = [child]
    let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [root.persistentModelID])
    #expect(result.count == 1)
    #expect(result[0].task.safeTitle == "Root")
}

@Test func childCollapsedUnderExpandedRoot() {
    let root = makeTask(id: 1, title: "Root")
    let child = makeTask(id: 2, title: "Child", parent: root)
    let grandchild = makeTask(id: 3, title: "Grandchild", parent: child)
    root.subtasks = [child]
    child.subtasks = [grandchild]
    let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [child.persistentModelID])
    #expect(result.count == 2)
    #expect(result[0].task.safeTitle == "Root")
    #expect(result[1].task.safeTitle == "Child")
}

// MARK: - Completed Children

@Test func includeCompletedFalseExcludesCompletedChildren() {
    let root = makeTask(id: 1, title: "Root")
    let child = makeTask(id: 2, title: "Done", parent: root)
    child.isCompleted = true
    root.subtasks = [child]
    let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [], includeCompleted: false)
    #expect(result.count == 1)
    #expect(result[0].task.safeTitle == "Root")
    #expect(result[0].subtaskSummary.total == 1, "Summary counts all subtasks regardless of completion")
    #expect(result[0].subtaskSummary.completed == 1)
    #expect(result[0].subtaskSummary.pending == 0)
}

@Test func includeCompletedTrueIncludesCompletedChildren() {
    let root = makeTask(id: 1, title: "Root")
    let child = makeTask(id: 2, title: "Done", parent: root)
    child.isCompleted = true
    root.subtasks = [child]
    let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [], includeCompleted: true)
    #expect(result.count == 2)
}

// MARK: - Subtask Count

@Test func leafTaskHasZeroSubtaskCount() {
    let root = makeTask(id: 1, title: "Leaf")
    let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [])
    #expect(result[0].subtaskSummary.isEmpty)
}

@Test func parentWithTwoChildrenHasCountTwo() {
    let root = makeTask(id: 1, title: "Parent")
    let c1 = makeTask(id: 2, title: "C1", parent: root)
    let c2 = makeTask(id: 3, title: "C2", parent: root)
    root.subtasks = [c1, c2]
    let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [])
    #expect(result[0].subtaskSummary.total == 2)
    #expect(result[0].subtaskSummary.pending == 2)
    #expect(result[0].subtaskSummary.completed == 0)
}

// MARK: - Flat Mode (no nesting)

@Test func flatModeShowsOnlyRoots() {
    let root = makeTask(id: 1, title: "Root")
    let child = makeTask(id: 2, title: "Child", parent: root)
    root.subtasks = [child]
    let result = TaskTreeFlattener.flatten(roots: [root], collapsed: [], nestSubtasks: false)
    #expect(result.count == 1)
    #expect(result[0].depth == 0)
    #expect(result[0].subtaskSummary.total == 1)
}

@Test func flatModeEachRootCarriesOwnSummary() {
    let root = makeTask(id: 1, title: "Root")
    let child = makeTask(id: 2, title: "Child", parent: root)
    root.subtasks = [child]
    let flat = TaskTreeFlattener.flatten(roots: [root, child], collapsed: [], nestSubtasks: false)
    #expect(flat.count == 2)
    #expect(flat[0].task.safeTitle == "Root")
    #expect(flat[0].subtaskSummary.total == 1)
    #expect(flat[1].task.safeTitle == "Child")
    #expect(flat[1].subtaskSummary.isEmpty)
}

@Test func flatModeIgnoresCollapse() {
    let root = makeTask(id: 1, title: "Root")
    let child = makeTask(id: 2, title: "Child", parent: root)
    root.subtasks = [child]
    let collapsedResult = TaskTreeFlattener.flatten(roots: [root], collapsed: [root.persistentModelID], nestSubtasks: false)
    let expandedResult = TaskTreeFlattener.flatten(roots: [root], collapsed: [], nestSubtasks: false)
    #expect(collapsedResult.count == 1)
    #expect(expandedResult.count == 1)
}

// MARK: - Deep Nesting

@Test func veryDeepNestingDoesNotCrash() {
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
    #expect(result.count == 16)
    for (index, node) in result.enumerated() {
        #expect(node.depth == index)
    }
}
