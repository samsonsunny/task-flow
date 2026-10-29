import Foundation

struct TodayDateWindow {
    let anchor: Date
    let start: Date
    let end: Date
    let days: [Date]

    init(anchor: Date, calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: anchor)
        let start = calendar.date(byAdding: .month, value: -12, to: day) ?? day
        let end = calendar.date(byAdding: .month, value: 24, to: day) ?? day

        self.anchor = day
        self.start = calendar.startOfDay(for: start)
        self.end = calendar.startOfDay(for: end)

        var days: [Date] = []
        var current = self.start
        while current <= self.end {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        self.days = days
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= start && day <= end
    }
}
