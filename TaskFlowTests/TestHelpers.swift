import Testing
import Foundation
import SwiftData
@testable import TaskFlow

// MARK: - Calendar & Date

func makeCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    calendar.firstWeekday = 2
    return calendar
}

func makeDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
}

// MARK: - Sort order assertions

func assertValidTaskSortOrders(_ tasks: [TaskItem]) {
    let sorted = tasks.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
    let orders = sorted.map { $0.sortOrder }
    let nonNil = orders.compactMap { $0 }
    #expect(nonNil.count == orders.count, "All sortOrders should be non-nil")
    #expect(Set(nonNil).count == nonNil.count, "sortOrders should be unique")
}

func assertValidListSortOrders(_ lists: [ReminderList]) {
    let sorted = lists.sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
    let orders = sorted.map { $0.sortOrder }
    let nonNil = orders.compactMap { $0 }
    #expect(nonNil.count == orders.count, "All sortOrders should be non-nil")
    #expect(Set(nonNil).count == nonNil.count, "sortOrders should be unique")
}

// MARK: - Task helpers

func makeTasks(sortOrders: [Int?]) -> [TaskItem] {
    sortOrders.enumerated().map { (i, order) in
        let task = TaskItem(taskTitle: "Task \(i)", dueDate: nil)
        task.sortOrder = order
        return task
    }
}

func sortedBySortOrder(_ tasks: [TaskItem]) -> [TaskItem] {
    tasks.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
}

func makeLists(sortOrders: [String?]) -> [ReminderList] {
    sortOrders.enumerated().map { (i, order) in
        let list = ReminderList(name: "List \(i)")
        list.sortOrder = order
        return list
    }
}

func sortedBySortOrder(_ lists: [ReminderList]) -> [ReminderList] {
    lists.sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
}
