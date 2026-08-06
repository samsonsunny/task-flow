import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@MainActor
struct ReschedulePresetTests {
    let container: ModelContainer
    let context: ModelContext
    let now: Date

    init() {
        container = TaskPreviewData.container()
        context = container.mainContext
        now = Date()
    }

    private func makeTask(title: String, date: Date?) -> TaskItem {
        let task = TaskItem(taskTitle: title, dueDate: date)
        task.taskId = UUID().uuidString
        context.insert(task)
        return task
    }

    private func allTasks() -> [TaskItem] {
        (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
    }

    // MARK: - TimelineViewModel single-task presets

    @Test func timeline_rescheduleToNone_clearsDueDate() {
        let task = makeTask(title: "T", date: now)
        let vm = ReminderSegmentViewModel(modelContext: context, segment: .today)
        vm.update(tasks: allTasks(), lists: [], now: now)

        vm.rescheduleToNone(task)

        #expect(task.dueDate == nil)
        let fetched = allTasks().first { $0.persistentModelID == task.persistentModelID }
        #expect(fetched?.dueDate == nil)
    }

    @Test func timeline_rescheduleToThisWeekend_setsWeekend() {
        let task = makeTask(title: "T", date: nil)
        let vm = ReminderSegmentViewModel(modelContext: context, segment: .today)
        vm.update(tasks: allTasks(), lists: [], now: now)

        vm.rescheduleToThisWeekend(task)

        let expected = ReminderSegmentViewModel.nextSaturday(from: now)
        #expect(task.dueDate.map { Calendar.current.isDate($0, inSameDayAs: expected) } == true)
    }

    @Test func timeline_rescheduleToNone_cancelsNotification() {
        let task = makeTask(title: "T", date: now)
        let vm = ReminderSegmentViewModel(modelContext: context, segment: .today)
        vm.update(tasks: allTasks(), lists: [], now: now)

        vm.rescheduleToNone(task)

        #expect(task.dueDate == nil)
    }

    // MARK: - TimelineViewModel bulk presets

    @Test func timeline_bulkRescheduleToNone_clearsAll() {
        let t1 = makeTask(title: "A", date: now)
        let t2 = makeTask(title: "B", date: now)
        let vm = ReminderSegmentViewModel(modelContext: context, segment: .today)
        vm.update(tasks: allTasks(), lists: [], now: now)

        vm.bulkRescheduleToNone([t1.persistentModelID, t2.persistentModelID])

        #expect(t1.dueDate == nil)
        #expect(t2.dueDate == nil)
    }

    @Test func timeline_bulkRescheduleToThisWeekend_setsAll() {
        let t1 = makeTask(title: "A", date: nil)
        let t2 = makeTask(title: "B", date: nil)
        let vm = ReminderSegmentViewModel(modelContext: context, segment: .today)
        vm.update(tasks: allTasks(), lists: [], now: now)

        vm.bulkRescheduleToThisWeekend([t1.persistentModelID, t2.persistentModelID])

        let expected = ReminderSegmentViewModel.nextSaturday(from: now)
        #expect(t1.dueDate.map { Calendar.current.isDate($0, inSameDayAs: expected) } == true)
        #expect(t2.dueDate.map { Calendar.current.isDate($0, inSameDayAs: expected) } == true)
    }

    @Test func timeline_bulkRescheduleToDate_appliesDateToAll() {
        let t1 = makeTask(title: "A", date: nil)
        let t2 = makeTask(title: "B", date: nil)
        let vm = ReminderSegmentViewModel(modelContext: context, segment: .today)
        vm.update(tasks: allTasks(), lists: [], now: now)

        let dueDate = Calendar.current.startOfDay(for: now)
        vm.bulkRescheduleToDate([t1.persistentModelID, t2.persistentModelID], dueDate: dueDate, hasTime: false)

        #expect(t1.dueDate == dueDate)
        #expect(t2.dueDate == dueDate)
    }

    // MARK: - ListDetailViewModel single-task presets

    @Test func detail_rescheduleTaskToNone_clearsDueDate() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let task = makeTask(title: "T", date: now)
        task.reminderList = list
        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        vm.update(tasks: allTasks(), lists: [list], allTasks: allTasks(), now: now)

        vm.rescheduleTaskToNone(task)

        #expect(task.dueDate == nil)
    }

    @Test func detail_rescheduleTaskToThisWeekend_setsWeekend() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let task = makeTask(title: "T", date: nil)
        task.reminderList = list
        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        vm.update(tasks: allTasks(), lists: [list], allTasks: allTasks(), now: now)

        vm.rescheduleTaskToThisWeekend(task)

        let expected = ReminderSegmentViewModel.nextSaturday(from: now)
        #expect(task.dueDate.map { Calendar.current.isDate($0, inSameDayAs: expected) } == true)
    }

    // MARK: - ListDetailViewModel bulk presets

    @Test func detail_bulkRescheduleToNone_clearsAll() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let t1 = makeTask(title: "A", date: now)
        let t2 = makeTask(title: "B", date: now)
        t1.reminderList = list
        t2.reminderList = list
        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        vm.update(tasks: allTasks(), lists: [list], allTasks: allTasks(), now: now)

        vm.bulkRescheduleToNone([t1.persistentModelID, t2.persistentModelID])

        #expect(t1.dueDate == nil)
        #expect(t2.dueDate == nil)
    }

    @Test func detail_bulkRescheduleToThisWeekend_setsAll() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let t1 = makeTask(title: "A", date: nil)
        let t2 = makeTask(title: "B", date: nil)
        t1.reminderList = list
        t2.reminderList = list
        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        vm.update(tasks: allTasks(), lists: [list], allTasks: allTasks(), now: now)

        vm.bulkRescheduleToThisWeekend([t1.persistentModelID, t2.persistentModelID])

        let expected = ReminderSegmentViewModel.nextSaturday(from: now)
        #expect(t1.dueDate.map { Calendar.current.isDate($0, inSameDayAs: expected) } == true)
        #expect(t2.dueDate.map { Calendar.current.isDate($0, inSameDayAs: expected) } == true)
    }

    @Test func detail_bulkRescheduleToDate_appliesDateToAll() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let t1 = makeTask(title: "A", date: nil)
        let t2 = makeTask(title: "B", date: nil)
        t1.reminderList = list
        t2.reminderList = list
        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        vm.update(tasks: allTasks(), lists: [list], allTasks: allTasks(), now: now)

        let dueDate = Calendar.current.startOfDay(for: now)
        vm.bulkRescheduleToDate([t1.persistentModelID, t2.persistentModelID], dueDate: dueDate, hasTime: false)

        #expect(t1.dueDate == dueDate)
        #expect(t2.dueDate == dueDate)
    }
}
