import SwiftUI

@Observable
final class TaskScheduleDatePickerViewModel {
    var dueDate: Date?
    var hasTime: Bool
    var expandedPicker: ExpandedPicker?

    init(initialDueDate: Date?) {
        let hasTimeVal: Bool
        if let date = initialDueDate {
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            hasTimeVal = components.hour != 0 || components.minute != 0
        } else {
            hasTimeVal = false
        }
        self.dueDate = initialDueDate
        self.hasTime = hasTimeVal
        self.expandedPicker = initialDueDate != nil ? .date : nil
    }

    func toggleDate(isEnabled: Bool) {
        if isEnabled {
            dueDate = dueDate ?? Date()
            expandedPicker = .date
        } else {
            dueDate = nil
            hasTime = false
            expandedPicker = nil
        }
    }

    func toggleTime(isEnabled: Bool) {
        if isEnabled {
            hasTime = true
            let calendar = Calendar.current
            let baseDate = dueDate ?? Date()
            var dayComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            let rounded = nearestRoundedHour()
            let timeComponents = calendar.dateComponents([.hour, .minute], from: rounded)
            dayComponents.hour = timeComponents.hour
            dayComponents.minute = timeComponents.minute
            dueDate = calendar.date(from: dayComponents) ?? rounded
            expandedPicker = .time
        } else {
            hasTime = false
            expandedPicker = nil
        }
    }

    enum ExpandedPicker {
        case date
        case time
    }
}
