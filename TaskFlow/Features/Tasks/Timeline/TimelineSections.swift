import Foundation
import SwiftData

struct TaskUIModel {
    enum UpcomingGroup: Identifiable {
        case categoryHeader(id: String, title: String)
        case daySection(id: String, date: Date, title: String, tasks: [TaskItem], isInHorizon: Bool)
        case monthSection(id: String, date: Date, title: String, dayGroups: [DayInMonth], isCollapsible: Bool)

        var id: String {
            switch self {
            case .categoryHeader(let id, _): return id
            case .daySection(let id, _, _, _, _): return id
            case .monthSection(let id, _, _, _, _): return id
            }
        }
    }

    struct DayInMonth: Identifiable {
        let id: String
        let date: Date
        let title: String
        let tasks: [TaskItem]
    }
    struct DatedSection: Identifiable, Hashable {
        enum Kind: Hashable {
            case overdue
            case day(Date)
            case month(monthStart: Date)
            case future
        }

        let id: String
        let kind: Kind
        let title: String
        let subtitle: String?
        let tasks: [TaskItem]
    }

    static func taskKey(for task: TaskItem) -> String {
        if let taskId = task.taskId, !taskId.isEmpty {
            return taskId
        }
        return String(describing: task.persistentModelID)
    }

    static func datedSections(
        from tasks: [TaskItem],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [DatedSection] {
        let dated = tasks.compactMap { task -> (TaskItem, Date)? in
            guard let due = task.dueDate else { return nil }
            return (task, calendar.startOfDay(for: due))
        }

        let todayStart = calendar.startOfDay(for: now)
        let horizonEndExclusive = calendar.date(byAdding: .day, value: 7, to: todayStart) ?? todayStart

        let currentMonthInterval = calendar.dateInterval(of: .month, for: todayStart)
        let currentMonthStart = currentMonthInterval?.start ?? todayStart
        let currentMonthEndExclusive = currentMonthInterval?.end ?? horizonEndExclusive

        let windowEndExclusive = calendar.date(byAdding: .month, value: 12, to: currentMonthStart) ?? currentMonthEndExclusive

        func sort(_ items: [TaskItem]) -> [TaskItem] {
            items.sorted { lhs, rhs in
                let lhsDue = calendar.startOfDay(for: lhs.dueDate ?? .distantFuture)
                let rhsDue = calendar.startOfDay(for: rhs.dueDate ?? .distantFuture)
                if lhsDue != rhsDue { return lhsDue < rhsDue }
                let lhsCreatedAt = lhs.createdAt ?? .distantPast
                let rhsCreatedAt = rhs.createdAt ?? .distantPast
                if lhsCreatedAt != rhsCreatedAt { return lhsCreatedAt > rhsCreatedAt }
                return taskKey(for: lhs) < taskKey(for: rhs)
            }
        }

        var sections: [DatedSection] = []

        // Overdue
        let overdueTasks: [TaskItem] = dated.compactMap { entry in
            let (task, dueStart) = entry
            guard task.isCompleted != true else { return nil }
            return dueStart < todayStart ? task : nil
        }
        if !overdueTasks.isEmpty {
            sections.append(
                DatedSection(
                    id: "overdue",
                    kind: .overdue,
                    title: "Overdue",
                    subtitle: nil,
                    tasks: sort(overdueTasks)
                )
            )
        }

        // Next 7 Days (D to D+6)
        for dayOffset in 0...6 {
            let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: todayStart) ?? todayStart
            let dayTasks = dated.compactMap { task, dueStart in
                calendar.isDate(dueStart, inSameDayAs: dayStart) ? task : nil
            }

            if !dayTasks.isEmpty {
                let title: String
                if dayOffset == 0 {
                    title = "Today"
                } else if dayOffset == 1 {
                    title = "Tomorrow"
                } else {
                    title = tabDateTitle(for: dayStart, calendar: calendar)
                }

                sections.append(
                    DatedSection(
                        id: "day-\(calendar.component(.year, from: dayStart))-\(calendar.ordinality(of: .day, in: .year, for: dayStart) ?? dayOffset)",
                        kind: .day(dayStart),
                        title: title,
                        subtitle: nil,
                        tasks: sort(dayTasks)
                    )
                )
            }
        }

        // Remainder of current month
        if horizonEndExclusive < currentMonthEndExclusive {
            let remainderTasks = dated.compactMap { task, dueStart in
                (dueStart >= horizonEndExclusive && dueStart < currentMonthEndExclusive) ? task : nil
            }
            if !remainderTasks.isEmpty {
                sections.append(
                    DatedSection(
                        id: "month-\(calendar.component(.year, from: currentMonthStart))-\(calendar.component(.month, from: currentMonthStart))",
                        kind: .month(monthStart: currentMonthStart),
                        title: monthTitle(for: currentMonthStart, relativeTo: todayStart, calendar: calendar),
                        subtitle: nil,
                        tasks: sort(remainderTasks)
                    )
                )
            }
        }

        // Next 11 months
        for offset in 1...11 {
            guard let monthStart = calendar.date(byAdding: .month, value: offset, to: currentMonthStart) else { continue }
            guard let interval = calendar.dateInterval(of: .month, for: monthStart) else { continue }
            let monthTasks = dated.compactMap { task, dueStart in
                (dueStart >= interval.start && dueStart < interval.end) ? task : nil
            }
            if !monthTasks.isEmpty {
                sections.append(
                    DatedSection(
                        id: "month-\(calendar.component(.year, from: interval.start))-\(calendar.component(.month, from: interval.start))",
                        kind: .month(monthStart: interval.start),
                        title: monthTitle(for: interval.start, relativeTo: todayStart, calendar: calendar),
                        subtitle: nil,
                        tasks: sort(monthTasks)
                    )
                )
            }
        }

        // Beyond window
        let beyondWindowTasks = dated.compactMap { task, dueStart in
            (dueStart >= windowEndExclusive) ? task : nil
        }
        if !beyondWindowTasks.isEmpty {
            sections.append(
                DatedSection(
                    id: "future",
                    kind: .future,
                    title: "Future",
                    subtitle: nil,
                    tasks: sort(beyondWindowTasks)
                )
            )
        }

        return sections
    }

    static func monthTitle(for monthStart: Date, relativeTo reference: Date, calendar: Calendar = .current) -> String {
        let month = calendar.component(.month, from: monthStart)
        let year = calendar.component(.year, from: monthStart)
        let refYear = calendar.component(.year, from: reference)

        let formatter = DateFormatter()
        if year == refYear {
            formatter.setLocalizedDateFormatFromTemplate("MMMM")
        } else {
            formatter.setLocalizedDateFormatFromTemplate("MMM yyyy")
        }
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? monthStart)
    }

    static func tabDateTitle(for date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE MMM d")
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: calendar.startOfDay(for: date))
    }

    static let tabDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE MMM d")
        return formatter
    }()

    static let chipDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()

    /// "Friday, May 29"
    static let upcomingDayTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        return formatter
    }()

    /// "Wed, Jun 18" — used outside the 7-day horizon
    static let compactDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE MMM d")
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    static func upcomingDayTitle(for date: Date, calendar: Calendar = .current) -> String {
        upcomingDayTitleFormatter.string(from: calendar.startOfDay(for: date))
    }

    static func compactDayTitle(for date: Date, calendar: Calendar = .current) -> String {
        compactDayFormatter.string(from: calendar.startOfDay(for: date))
    }
}
