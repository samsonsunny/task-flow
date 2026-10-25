import SwiftUI

/// Compact seven-day calendar strip used by the Upcoming filter.
///
/// The visible week always follows the selected date, so tapping a day,
/// swiping to another week, or jumping from the calendar picker all keep the
/// selected day highlighted and anchored to the same weekday.
struct WeekStripView: View {
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    private static let cellSpacing: CGFloat = 3
    private static let cornerRadius: CGFloat = 10

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter
    }()

    private static let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("d")
        return formatter
    }()

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
        return formatter
    }()

    private var weekDays: [Date] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start else {
            return [calendar.startOfDay(for: selectedDate)]
        }
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }
    }

    var body: some View {
        HStack(spacing: Self.cellSpacing) {
            ForEach(weekDays, id: \.self) { date in
                dayCell(for: date)
            }
        }
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded(handleSwipe)
        )
    }

    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return Button {
            let startOfDay = calendar.startOfDay(for: date)
            guard startOfDay != selectedDate else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedDate = startOfDay
        } label: {
            VStack(spacing: 3) {
                Text(isToday ? "TODAY" : Self.weekdayFormatter.string(from: date))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isToday ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(Self.dayNumberFormatter.string(from: date))
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isToday && !isSelected ? AppTheme.colors.tint : AppTheme.colors.textPrimary)
                    .lineLimit(1)

                Circle()
                    .fill(isSelected ? AppTheme.colors.tint : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(isSelected ? AppTheme.colors.tint.opacity(0.12) : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isToday
            ? "\(Self.accessibilityFormatter.string(from: date)), today"
            : Self.accessibilityFormatter.string(from: date)
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func handleSwipe(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        guard abs(horizontal) > 40,
              abs(horizontal) > abs(value.translation.height)
        else { return }

        let dayOffset = horizontal < 0 ? 7 : -7
        guard let newDate = calendar.date(byAdding: .day, value: dayOffset, to: selectedDate) else {
            return
        }

        Haptics.selection()
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = calendar.startOfDay(for: newDate)
        }
    }
}
