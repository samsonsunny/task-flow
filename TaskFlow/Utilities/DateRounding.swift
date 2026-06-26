import Foundation

public func nearestRoundedHour(from date: Date = Date()) -> Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    let totalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
    let rounded = ((totalMinutes + 29) / 30) * 30
    let clamped = rounded % (24 * 60)
    return calendar.date(bySettingHour: clamped / 60, minute: clamped % 60, second: 0, of: date) ?? date
}
