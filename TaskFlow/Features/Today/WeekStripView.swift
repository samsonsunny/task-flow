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
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -10, to: today)!
        return (0..<41).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Self.cellSpacing) {
                    ForEach(weekDays, id: \.self) { date in
                        dayCell(for: date)
                            .id(date)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollTargetLayout()
            .onChange(of: selectedDate) { _, newValue in
                let day = calendar.startOfDay(for: newValue)
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(day, anchor: .leading)
                }
            }
            .onAppear {
                let day = calendar.startOfDay(for: selectedDate)
                DispatchQueue.main.async {
                    proxy.scrollTo(day, anchor: .leading)
                }
            }
        }
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
                Text(isToday ? "TODAY" : Self.weekdayFormatter.string(from: date).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isToday ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(Self.dayNumberFormatter.string(from: date))
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isToday && !isSelected ? AppTheme.colors.tint : AppTheme.colors.textPrimary)
                    .lineLimit(1)

                Circle()
                    .fill(isToday ? AppTheme.colors.tint : Color.clear)
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
            .frame(width: 52)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isToday
            ? "\(Self.accessibilityFormatter.string(from: date)), today"
            : Self.accessibilityFormatter.string(from: date)
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
