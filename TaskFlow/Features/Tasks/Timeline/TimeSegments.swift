import Foundation
import SwiftUI

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
        case .overdue: return "No overdue reminders"
        }
    }

    var emptyMessage: String {
        switch self {
        case .today: return "Reminders due today will appear here."
        case .tomorrow: return "Reminders due tomorrow will appear here."
        case .upcoming: return "Reminders due soon will appear here."
        case .overdue: return "Reminders past their due date will appear here."
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
        calendar: Calendar = .current
    ) -> [TaskItem] {
        tasks.sorted { lhs, rhs in
            let lhsDue = lhs.dueDate.map { calendar.startOfDay(for: $0) } ?? .distantFuture
            let rhsDue = rhs.dueDate.map { calendar.startOfDay(for: $0) } ?? .distantFuture
            if lhsDue != rhsDue {
                return lhsDue < rhsDue
            }

            let lhsCreatedAt = lhs.createdAt ?? .distantPast
            let rhsCreatedAt = rhs.createdAt ?? .distantPast
            if lhsCreatedAt != rhsCreatedAt {
                return lhsCreatedAt > rhsCreatedAt
            }

            return TaskUIModel.taskKey(for: lhs) < TaskUIModel.taskKey(for: rhs)
        }
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
        let windowEnd = calendar.date(byAdding: .month, value: 12, to: currentMonthStart) ?? calendar.startOfDay(for: now)

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

        var groups: [TaskUIModel.UpcomingGroup] = []

        for offset in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            let tasks = tasksOn(dayStart)
            let title = TaskUIModel.compactDayTitle(for: dayStart, calendar: calendar)
            let id = "h7-\(calendar.component(.year, from: dayStart))-\(calendar.ordinality(of: .day, in: .year, for: dayStart) ?? offset)"
            groups.append(.daySection(id: id, date: dayStart, title: title, tasks: tasks, isInHorizon: true))
        }

        let nextYearTasks = allUpcoming.filter { task in
            guard let due = task.dueDate else { return false }
            let dayStart = calendar.startOfDay(for: due)
            return dayStart >= horizonEnd && dayStart < windowEnd
        }

        let startMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: horizonEnd))!
        let endMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: windowEnd))!

        var monthStart = startMonth
        while monthStart < endMonth {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { break }

            let monthTasks = nextYearTasks.filter { task in
                guard let due = task.dueDate else { return false }
                return due >= monthStart && due < nextMonth
            }

            let monthTitle = TaskUIModel.monthTitle(for: monthStart, relativeTo: todayStart, calendar: calendar)

            let dayGroups: [TaskUIModel.DayInMonth]
            if !monthTasks.isEmpty {
                let sortedDates = Set(monthTasks.compactMap { $0.dueDate.map { calendar.startOfDay(for: $0) } }).sorted()
                dayGroups = sortedDates.map { date in
                    let tasks = sortedTasks(
                        monthTasks.filter { task in
                            guard let due = task.dueDate else { return false }
                            return calendar.isDate(due, inSameDayAs: date)
                        },
                        for: .upcoming,
                        calendar: calendar
                    )
                    let dayTitle = TaskUIModel.compactDayTitle(for: date, calendar: calendar)
                    let id = "d-\(calendar.component(.year, from: date))-\(calendar.ordinality(of: .day, in: .year, for: date) ?? 0)"
                    return TaskUIModel.DayInMonth(id: id, date: date, title: dayTitle, tasks: tasks)
                }
            } else {
                dayGroups = []
            }

            let mid = "m-\(calendar.component(.year, from: monthStart))-\(calendar.component(.month, from: monthStart))"
            groups.append(.monthSection(id: mid, date: monthStart, title: monthTitle, dayGroups: dayGroups, isCollapsible: false))

            monthStart = nextMonth
        }

        let beyondTasks = allUpcoming.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.startOfDay(for: due) >= windowEnd
        }

        if !beyondTasks.isEmpty {
            let monthStarts = Set(beyondTasks.compactMap { task -> Date? in
                guard let due = task.dueDate else { return nil }
                let comps = calendar.dateComponents([.year, .month], from: due)
                return calendar.date(from: comps)
            }).sorted()

            for monthStart in monthStarts {
                let monthTasks = beyondTasks.filter { task in
                    guard let due = task.dueDate else { return false }
                    return calendar.isDate(due, equalTo: monthStart, toGranularity: .month)
                }

                let monthTitle = TaskUIModel.monthTitle(for: monthStart, relativeTo: todayStart, calendar: calendar)
                let sortedDates = Set(monthTasks.compactMap { $0.dueDate.map { calendar.startOfDay(for: $0) } }).sorted()

                let dayGroups: [TaskUIModel.DayInMonth] = sortedDates.map { date in
                    let tasks = sortedTasks(
                        monthTasks.filter { task in
                            guard let due = task.dueDate else { return false }
                            return calendar.isDate(due, inSameDayAs: date)
                        },
                        for: .upcoming,
                        calendar: calendar
                    )
                    let dayTitle = TaskUIModel.compactDayTitle(for: date, calendar: calendar)
                    let id = "d-\(calendar.component(.year, from: date))-\(calendar.ordinality(of: .day, in: .year, for: date) ?? 0)"
                    return TaskUIModel.DayInMonth(id: id, date: date, title: dayTitle, tasks: tasks)
                }

                let mid = "b-\(calendar.component(.year, from: monthStart))-\(calendar.component(.month, from: monthStart))"
                groups.append(.monthSection(id: mid, date: monthStart, title: monthTitle, dayGroups: dayGroups, isCollapsible: false))
            }
        }

        return groups
    }
}
