import SwiftUI

/// Compact seven-day calendar strip used by the Upcoming filter.
///
/// The visible week always follows the selected date, so tapping a day,
/// swiping to another week, or jumping from the calendar picker all keep the
/// selected day highlighted and anchored to the same weekday.
struct WeekStripView: View {
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    private static let cellSpacing: CGFloat = 10
    private static let cornerRadius: CGFloat = 16

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
                    proxy.scrollTo(day, anchor: UnitPoint(x: 0.05, y: 0.5))
                }
            }
            .onAppear {
                let day = calendar.startOfDay(for: selectedDate)
                DispatchQueue.main.async {
                    proxy.scrollTo(day, anchor: UnitPoint(x: 0.05, y: 0.5))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("scrollTodayToStart"))) { _ in
                let today = calendar.startOfDay(for: Date())
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(today, anchor: UnitPoint(x: 0.05, y: 0.5))
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
            VStack(spacing: 5) {
                Text(Self.weekdayFormatter.string(from: date).uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : (isToday ? AppTheme.colors.tint : AppTheme.colors.textSecondary))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(Self.dayNumberFormatter.string(from: date))
                    .font(.system(size: 20, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? .white : (isToday ? AppTheme.colors.tint : AppTheme.colors.textPrimary))
                    .lineLimit(1)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(minWidth: 64)
            .background(
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(isSelected ? AppTheme.colors.tint : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .stroke(isToday && !isSelected ? AppTheme.colors.tint.opacity(0.7) : Color(.separator).opacity(0.3), lineWidth: isToday && !isSelected ? 1.8 : 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
            .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isToday
            ? "\(Self.accessibilityFormatter.string(from: date)), today"
            : Self.accessibilityFormatter.string(from: date)
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
