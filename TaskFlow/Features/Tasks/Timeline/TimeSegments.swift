import Foundation
import SwiftUI
import SwiftData

enum ReminderSegment: String, CaseIterable, Identifiable, Hashable {
    case today
    case tomorrow
    case upcoming
    case overdue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .upcoming: return "Upcoming"
        case .overdue: return "Overdue"
        }
    }

    var navigationTitle: String {
        switch self {
        case .today: return "Ready"
        case .tomorrow: return "Prepare"
        case .upcoming: return "Plan"
        case .overdue: return "Overdue"
        }
    }

    var iconName: String {
        switch self {
        case .today: return "calendar.circle.fill"
        case .tomorrow: return "sunrise.fill"
        case .upcoming: return "calendar.badge.clock"
        case .overdue: return "exclamationmark.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .today: return AppTheme.colors.primaryAction
        case .tomorrow: return AppTheme.colors.success
        case .upcoming: return AppTheme.colors.warning
        case .overdue: return AppTheme.colors.error
        }
    }

    var usesGroupedSections: Bool {
        switch self {
        case .upcoming: return true
        case .today, .tomorrow, .overdue: return false
        }
    }

    var includesLaterSection: Bool {
        false
    }

    var tabTitle: String {
        title
    }

    var accessibilityIdentifier: String {
        "reminder-segment-\(rawValue)"
    }

    func subtitle(now: Date, calendar: Calendar = .current) -> String? {
        switch self {
        case .today:
            return TaskUIModel.tabDateFormatter.string(from: now)
        case .tomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
            return TaskUIModel.tabDateFormatter.string(from: tomorrow)
        case .upcoming:
            let start = ReminderSegmentLogic.upcomingStart(now: now, calendar: calendar)
            return "From \(TaskUIModel.chipDateFormatter.string(from: start))"
        case .overdue:
            return nil
        }
    }

    var emptyTitle: String {
        switch self {
        case .today: return "Nothing due today"
        case .tomorrow: return "Nothing due tomorrow"
        case .upcoming: return "Nothing in Upcoming"
        case .overdue: return "No overdue tasks"
        }
    }

    var emptyMessage: String {
        switch self {
        case .today: return "Tasks due today will appear here."
        case .tomorrow: return "Tasks due tomorrow will appear here."
        case .upcoming: return "Tasks due soon will appear here."
        case .overdue: return "Tasks past their due date will appear here."
        }
    }
}

enum ReminderSegmentLogic {
    static func filteredTasks(
        _ tasks: [TaskItem],
        for segment: ReminderSegment,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [TaskItem] {
        let todayStart = calendar.startOfDay(for: now)

        return tasks.filter { task in
            let isCompleted = task.isCompleted == true
            let dueStart = task.dueDate.map { calendar.startOfDay(for: $0) }

            switch segment {
            case .today:
                guard !isCompleted, let dueDate = task.dueDate else { return false }
                guard calendar.isDate(calendar.startOfDay(for: dueDate), inSameDayAs: todayStart) else { return false }
                if task.hasTime == true {
                    return dueDate >= now
                }
                return true
            case .tomorrow:
                guard !isCompleted, let dueDate = task.dueDate else { return false }
                let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart
                guard calendar.isDate(calendar.startOfDay(for: dueDate), inSameDayAs: tomorrowStart) else { return false }
                if task.hasTime == true {
                    return dueDate >= now
                }
                return true
            case .upcoming:
                guard !isCompleted, let dueStart else { return false }
                let start = upcomingStart(now: now, calendar: calendar)
                return dueStart >= start
            case .overdue:
                guard !isCompleted, let dueDate = task.dueDate else { return false }
                if task.hasTime == true {
                    return dueDate < now
                } else {
                    return calendar.startOfDay(for: dueDate) < todayStart
                }
            }
        }
    }

    static func count(
        for segment: ReminderSegment,
        tasks: [TaskItem],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        filteredTasks(tasks, for: segment, now: now, calendar: calendar).count
    }

    static func badgeCount(
        _ tasks: [TaskItem],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        filteredTasks(tasks, for: .overdue, now: now, calendar: calendar).count
        + filteredTasks(tasks, for: .today, now: now, calendar: calendar).count
    }

    static func datedSections(
        from tasks: [TaskItem],
        for segment: ReminderSegment,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [TaskUIModel.DatedSection] {
        return TaskUIModel.datedSections(
            from: filteredTasks(tasks, for: segment, now: now, calendar: calendar).filter { $0.dueDate != nil },
            now: now,
            calendar: calendar
        )
        .filter { !$0.tasks.isEmpty }
    }

    static func sortedTasks(
        _ tasks: [TaskItem],
        for segment: ReminderSegment,
        customOrderIndex: [String: Int]? = nil,
        calendar: Calendar = .current
    ) -> [TaskItem] {
        if let customOrderIndex, !customOrderIndex.isEmpty {
            return tasks.sorted { (lhs: TaskItem, rhs: TaskItem) -> Bool in
                let lhsOrder = customOrderIndex[lhs.persistentModelID.stableKey] ?? Int.max
                let rhsOrder = customOrderIndex[rhs.persistentModelID.stableKey] ?? Int.max
                if lhsOrder != rhsOrder {
                    return lhsOrder < rhsOrder
                }
                return defaultSort(lhs, rhs: rhs, calendar: calendar)
            }
        }

        return tasks.sorted { (lhs: TaskItem, rhs: TaskItem) -> Bool in
            defaultSort(lhs, rhs: rhs, calendar: calendar)
        }
    }

    private static func defaultSort(_ lhs: TaskItem, rhs: TaskItem, calendar: Calendar) -> Bool {
        let lhsDue = lhs.dueDate.map { calendar.startOfDay(for: $0) } ?? .distantFuture
        let rhsDue = rhs.dueDate.map { calendar.startOfDay(for: $0) } ?? .distantFuture
        if lhsDue != rhsDue {
            return lhsDue < rhsDue
        }

        let lhsCreatedAt = lhs.createdAt ?? .distantPast
        let rhsCreatedAt = rhs.createdAt ?? .distantPast
        if lhsCreatedAt != rhsCreatedAt {
            return lhsCreatedAt < rhsCreatedAt
        }

        return TaskUIModel.taskKey(for: lhs) < TaskUIModel.taskKey(for: rhs)
    }

    static func upcomingStart(now: Date, calendar: Calendar = .current) -> Date {
        let todayStart = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: 2, to: todayStart) ?? todayStart
    }

    static func upcomingGroups(
        from tasks: [TaskItem],
        now: Date,
        calendar: Calendar = .current
    ) -> [TaskUIModel.UpcomingGroup] {
        let allUpcoming = filteredTasks(tasks, for: .upcoming, now: now, calendar: calendar)
        let start = upcomingStart(now: now, calendar: calendar)
        let todayStart = calendar.startOfDay(for: now)
        let horizonEnd = calendar.date(byAdding: .day, value: 7, to: start) ?? start

        let currentMonthStart = calendar.dateInterval(of: .month, for: todayStart)?.start ?? todayStart
        let gridEnd = calendar.date(byAdding: .month, value: 2, to: currentMonthStart) ?? currentMonthStart
        let yearWindowEnd = calendar.date(byAdding: .month, value: 12, to: currentMonthStart) ?? gridEnd

        func tasksOn(_ dayStart: Date) -> [TaskItem] {
            sortedTasks(
                allUpcoming.filter { task in
                    guard let due = task.dueDate else { return false }
                    return calendar.isDate(due, inSameDayAs: dayStart)
                },
                for: .upcoming,
                calendar: calendar
            )
        }

        func dayGroups(from monthTasks: [TaskItem]) -> [TaskUIModel.DayInMonth] {
            let sortedDates = Set(monthTasks.compactMap { $0.dueDate.map { calendar.startOfDay(for: $0) } }).sorted()
            return sortedDates.map { date in
                let tasks = sortedTasks(
                    monthTasks.filter { task in
                        guard let due = task.dueDate else { return false }
                        return calendar.isDate(due, inSameDayAs: date)
                    },
                    for: .upcoming,
                    calendar: calendar
                )
                let id = "d-\(calendar.component(.year, from: date))-\(calendar.ordinality(of: .day, in: .year, for: date) ?? 0)"
                return TaskUIModel.DayInMonth(id: id, date: date, title: TaskUIModel.compactDayTitle(for: date, calendar: calendar), tasks: tasks)
            }
        }

        var groups: [TaskUIModel.UpcomingGroup] = []
        var offset = 0

        var monthStart = currentMonthStart
        while monthStart < yearWindowEnd {
            guard let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) else { break }
            let monthTitle = TaskUIModel.monthTitle(for: monthStart, relativeTo: todayStart, calendar: calendar)

            if monthStart < gridEnd {
                let firstDay = max(monthStart, start)
                if firstDay < nextMonthStart {
                    let monthID = "m-\(calendar.component(.year, from: monthStart))-\(calendar.component(.month, from: monthStart))"
                    groups.append(.monthHeader(id: monthID, date: monthStart, title: monthTitle))

                    var day = firstDay
                    while day < nextMonthStart {
                        let tasks = tasksOn(day)
                        let title = TaskUIModel.compactDayTitle(for: day, calendar: calendar)
                        let isInHorizon = day < horizonEnd
                        let id = "u-\(calendar.component(.year, from: day))-\(calendar.ordinality(of: .day, in: .year, for: day) ?? offset)"
                        groups.append(.daySection(id: id, date: day, title: title, tasks: tasks, isInHorizon: isInHorizon))
                        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                        day = nextDay
                        offset += 1
                    }
                }
            } else {
                let monthTasks = allUpcoming.filter { task in
                    guard let due = task.dueDate else { return false }
                    return due >= monthStart && due < nextMonthStart
                }
                let dayGroups = dayGroups(from: monthTasks)
                let mid = "m2-\(calendar.component(.year, from: monthStart))-\(calendar.component(.month, from: monthStart))"
                groups.append(.monthSection(id: mid, date: monthStart, title: monthTitle, dayGroups: dayGroups, isCollapsible: false))
            }

            monthStart = nextMonthStart
        }

        return groups
    }
}

