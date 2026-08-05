import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@MainActor
struct DueDatePresetTests {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - nextSaturday

    @Test func nextSaturday_midWeek_returnsUpcomingSaturday() {
        let monday = day(2026, 6, 15)
        let result = ReminderSegmentViewModel.nextSaturday(from: monday, calendar: calendar)
        #expect(calendar.isDate(result, inSameDayAs: day(2026, 6, 20)))
    }

    @Test func nextSaturday_friday_returnsFollowingDay() {
        let friday = day(2026, 6, 19)
        let result = ReminderSegmentViewModel.nextSaturday(from: friday, calendar: calendar)
        #expect(calendar.isDate(result, inSameDayAs: day(2026, 6, 20)))
    }

    @Test func nextSaturday_alreadySaturday_returnsToday() {
        let saturday = day(2026, 6, 20)
        let result = ReminderSegmentViewModel.nextSaturday(from: saturday, calendar: calendar)
        #expect(calendar.isDate(result, inSameDayAs: saturday))
    }

    @Test func nextSaturday_alreadySunday_returnsToday() {
        let sunday = day(2026, 6, 21)
        let result = ReminderSegmentViewModel.nextSaturday(from: sunday, calendar: calendar)
        #expect(calendar.isDate(result, inSameDayAs: sunday))
    }

    // MARK: - nextMonth

    @Test func nextMonth_sameDayOfMonth() {
        let result = ReminderSegmentViewModel.nextMonth(from: day(2026, 6, 15), calendar: calendar)
        #expect(calendar.isDate(result, inSameDayAs: day(2026, 7, 15)))
    }

    @Test func nextMonth_clampsShortMonth() {
        let result = ReminderSegmentViewModel.nextMonth(from: day(2026, 1, 31), calendar: calendar)
        #expect(calendar.isDate(result, inSameDayAs: day(2026, 2, 28)))
    }

    @Test func nextMonth_clampsLeapYear() {
        let result = ReminderSegmentViewModel.nextMonth(from: day(2024, 1, 31), calendar: calendar)
        #expect(calendar.isDate(result, inSameDayAs: day(2024, 2, 29)))
    }

    @Test func nextMonth_yearBoundary() {
        let result = ReminderSegmentViewModel.nextMonth(from: day(2026, 12, 31), calendar: calendar)
        #expect(calendar.isDate(result, inSameDayAs: day(2027, 1, 31)))
    }
}
