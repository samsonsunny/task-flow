import SwiftUI

/// Compact calendar strip used by the Upcoming filter.
///
/// The strip renders the current three-year date window lazily, so tapping a
/// day, swiping, or jumping from the calendar picker all keep the selected day
/// highlighted without materializing every date at once.
struct WeekStripView: View {
    let days: [Date]
    @Binding var selectedDate: Date
    let scrollRequestToken: Int
    let dateWindowVersion: Int
    let onDayTap: (Date) -> Void

    @State private var scrollAnimation = ScrollAnimationController()

    private let calendar = Calendar.current
    private static let cellSpacing: CGFloat = 10
    private static let cornerRadius: CGFloat = 16
    private static let regularMinWidth: CGFloat = 64
    private static let specialMinWidth: CGFloat = 100

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

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Self.cellSpacing) {
                    ForEach(days, id: \.self) { date in
                        dayCell(for: date)
                            .id(date)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
                .background(ScrollViewLocator(controller: scrollAnimation))
            }
            .scrollTargetLayout()
            .onChange(of: selectedDate) { _, newValue in
                scroll(to: newValue, proxy: proxy, animated: true)
            }
            .onAppear {
                DispatchQueue.main.async {
                    scroll(to: selectedDate, proxy: proxy, animated: false)
                }
            }
            .onChange(of: scrollRequestToken) { _, _ in
                scroll(to: calendar.startOfDay(for: Date()), proxy: proxy, animated: true)
            }
            .onChange(of: dateWindowVersion) { _, _ in
                DispatchQueue.main.async {
                    scroll(to: selectedDate, proxy: proxy, animated: false)
                }
            }
        }
    }

    private func scroll(
        to date: Date,
        proxy: ScrollViewProxy,
        animated: Bool
    ) {
        scrollAnimation.halt()
        let day = calendar.startOfDay(for: date)
        let anchor = UnitPoint(x: 0.05, y: 0.5)
        if animated {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(day, anchor: anchor)
            }
        } else {
            proxy.scrollTo(day, anchor: anchor)
        }
    }

    private func relativeLabel(for date: Date) -> String? {
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        return nil
    }

    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let specialLabel = relativeLabel(for: date)
        let isSpecial = specialLabel != nil
        let shape = RoundedRectangle(cornerRadius: isSpecial ? 14 : Self.cornerRadius)

        return Button {
            let startOfDay = calendar.startOfDay(for: date)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onDayTap(startOfDay)
            if startOfDay != selectedDate {
                selectedDate = startOfDay
            }
        } label: {
            VStack(spacing: 5) {
                Text((specialLabel ?? Self.weekdayFormatter.string(from: date)).uppercased())
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
            .padding(.horizontal, isSpecial ? 18 : 14)
            .frame(minWidth: isSpecial ? Self.specialMinWidth : Self.regularMinWidth)
            .background(
                shape
                    .fill(
                        isSelected
                            ? AppTheme.colors.tint
                            : (isToday ? AppTheme.colors.tint.opacity(0.12) : Color(.secondarySystemGroupedBackground))
                    )
            )
            .overlay(
                shape
                    .stroke(
                        isSelected
                            ? Color.clear
                            : (isToday ? AppTheme.colors.tint.opacity(0.35) : AppTheme.colors.cardBorder),
                        lineWidth: isSelected ? 0 : 1
                    )
            )
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: date))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func accessibilityLabel(for date: Date) -> String {
        let base = Self.accessibilityFormatter.string(from: date)
        if calendar.isDateInToday(date) { return "\(base), today" }
        if calendar.isDateInTomorrow(date) { return "\(base), tomorrow" }
        if calendar.isDateInYesterday(date) { return "\(base), yesterday" }
        return base
    }
}
