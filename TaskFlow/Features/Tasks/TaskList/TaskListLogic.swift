import Foundation
import SwiftData

enum TaskListLogic {
    static func taskKey(for task: TaskItem) -> String {
        if let taskId = task.taskId, !taskId.isEmpty {
            return taskId
        }
        return String(describing: task.persistentModelID)
    }

    static func filteredTasks(_ tasks: [TaskItem], for bucket: TaskBucket, now: Date = Date(), calendar: Calendar = .current) -> [TaskItem] {
        let todayStart = calendar.startOfDay(for: now)
        let tomorrowStart = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart)
        return tasks.filter { task in
            guard let dueDate = task.dueDate else {
                return bucket == .someday
            }
            switch bucket {
            case .today:
                return calendar.isDateInToday(dueDate)
            case .tomorrow:
                return calendar.isDateInTomorrow(dueDate)
            case .upcoming:
                let dueStart = calendar.startOfDay(for: dueDate)
                return dueStart > tomorrowStart
            case .someday:
                return false
            }
        }
    }

    static func sortUpcomingTasks(_ items: [TaskItem], calendar: Calendar = .current) -> [TaskItem] {
        items.sorted { lhs, rhs in
            let lhsDue = calendar.startOfDay(for: lhs.dueDate ?? .distantFuture)
            let rhsDue = calendar.startOfDay(for: rhs.dueDate ?? .distantFuture)
            if lhsDue != rhsDue {
                return lhsDue < rhsDue
            }
            let lhsCreatedAt = lhs.createdAt ?? .distantPast
            let rhsCreatedAt = rhs.createdAt ?? .distantPast
            if lhsCreatedAt != rhsCreatedAt {
                return lhsCreatedAt > rhsCreatedAt
            }
            return taskKey(for: lhs) < taskKey(for: rhs)
        }
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
        let nextFiveEndExclusive = calendar.date(byAdding: .day, value: 7, to: todayStart) ?? todayStart

        let currentMonthInterval = calendar.dateInterval(of: .month, for: todayStart)
        let currentMonthStart = currentMonthInterval?.start ?? todayStart
        let currentMonthEndExclusive = currentMonthInterval?.end ?? nextFiveEndExclusive

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

        let overdueTasks: [TaskItem] = dated.compactMap { entry in
            let (task, dueStart) = entry
            guard task.isCompleted != true else { return nil }
            return dueStart < todayStart ? task : nil
        }
        sections.append(
            DatedSection(
                id: "overdue",
                kind: .overdue,
                title: "Overdue",
                subtitle: nil,
                tasks: sort(overdueTasks)
            )
        )

        for dayOffset in 0...6 {
            let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: todayStart) ?? todayStart
            let dayTasks = dated.compactMap { task, dueStart in
                calendar.isDate(dueStart, inSameDayAs: dayStart) ? task : nil
            }

            let title: String
            let subtitle: String?
            if dayOffset == 0 {
                title = "Today"
                subtitle = nil
            } else if dayOffset == 1 {
                title = "Tomorrow"
                subtitle = nil
            } else {
                title = tabDateTitle(for: dayStart, calendar: calendar)
                subtitle = nil
            }

            sections.append(
                DatedSection(
                    id: "day-\(calendar.component(.year, from: dayStart))-\(calendar.ordinality(of: .day, in: .year, for: dayStart) ?? dayOffset)",
                    kind: .day(dayStart),
                    title: title,
                    subtitle: subtitle,
                    tasks: sort(dayTasks)
                )
            )
        }

        // Remainder of current month after the "Next 5 Days" window.
        if nextFiveEndExclusive < currentMonthEndExclusive {
            let remainderTasks = dated.compactMap { task, dueStart in
                (dueStart >= nextFiveEndExclusive && dueStart < currentMonthEndExclusive) ? task : nil
            }
            sections.append(
                DatedSection(
                    id: "month-\(calendar.component(.year, from: currentMonthStart))-\(calendar.component(.month, from: currentMonthStart))",
                    kind: .month(monthStart: currentMonthStart),
                    title: monthTitle(for: currentMonthStart, relativeTo: todayStart),
                    subtitle: nil,
                    tasks: sort(remainderTasks)
                )
            )
        }

        // Next 11 months (month buckets).
        for offset in 1...11 {
            guard let monthStart = calendar.date(byAdding: .month, value: offset, to: currentMonthStart) else { continue }
            guard let interval = calendar.dateInterval(of: .month, for: monthStart) else { continue }
            let monthTasks = dated.compactMap { task, dueStart in
                (dueStart >= interval.start && dueStart < interval.end) ? task : nil
            }
            sections.append(
                DatedSection(
                    id: "month-\(calendar.component(.year, from: interval.start))-\(calendar.component(.month, from: interval.start))",
                    kind: .month(monthStart: interval.start),
                    title: monthTitle(for: interval.start, relativeTo: todayStart),
                    subtitle: nil,
                    tasks: sort(monthTasks)
                )
            )
        }

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
}
