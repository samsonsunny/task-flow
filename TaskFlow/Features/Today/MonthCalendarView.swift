import SwiftUI

/// Expanded month calendar used by the Scheduled screen.
///
/// Renders a six-week grid for the displayed month, highlights the selected day,
/// marks today, and shows a dot under every day that has tasks.
struct MonthCalendarView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    let taskDays: Set<Date>
    let onDayTap: (Date) -> Void

    @State private var isExpanded = false

    private let calendar = Calendar.current
    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private static let cellHeight: CGFloat = 52

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d, yyyy")
        return formatter
    }()

    private static let monthOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter
    }()

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()

    var body: some View {
        VStack(spacing: 12) {
            monthHeader
            weekdayHeader
            if isExpanded {
                monthGrid
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                weekGrid
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 16)
        .onChange(of: selectedDate) { _, newValue in
            let day = calendar.startOfDay(for: newValue)
            guard !calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month) else { return }
            displayedMonth = day
        }
    }

    private var monthTitleText: String {
        let currentYear = calendar.component(.year, from: Date())
        let displayedYear = calendar.component(.year, from: displayedMonth)
        if currentYear == displayedYear {
            return Self.monthOnlyFormatter.string(from: displayedMonth)
        } else {
            return Self.monthYearFormatter.string(from: displayedMonth)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(monthTitleText)
                        .font(.headline)
                        .foregroundStyle(AppTheme.colors.textPrimary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.colors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(monthTitleText), \(isExpanded ? "collapse calendar" : "expand calendar")")

            Spacer()

            if isExpanded {
                HStack(spacing: 8) {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.colors.tint)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Previous month")

                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.colors.tint)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Next month")
                }
                .transition(.opacity)
            }
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Self.columns, spacing: 0) {
            ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .frame(height: Self.cellHeight)
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontal = value.translation.width
                    guard abs(horizontal) > abs(value.translation.height),
                          abs(horizontal) > 40 else { return }
                    changeMonth(by: horizontal < 0 ? 1 : -1)
                }
        )
    }

    private var weekGrid: some View {
        LazyVGrid(columns: Self.columns, spacing: 0) {
            ForEach(weekCells, id: \.self) { date in
                dayCell(for: date)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontal = value.translation.width
                    guard abs(horizontal) > abs(value.translation.height),
                          abs(horizontal) > 40 else { return }
                    changeWeek(by: horizontal < 0 ? 1 : -1)
                }
        )
    }

    private func dayCell(for date: Date) -> some View {
        let day = calendar.startOfDay(for: date)
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        let hasTasks = taskDays.contains(day)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedDate = day
            onDayTap(day)
        } label: {
            VStack(spacing: 4) {
                Text(dayNumber(for: day))
                    .font(.body.weight(isSelected || isToday ? .semibold : .regular))
                    .foregroundStyle(numberColor(isSelected: isSelected, isToday: isToday))
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(isSelected ? AppTheme.colors.tint : Color.clear)
                    )

                Circle()
                    .fill(dotColor(isSelected: isSelected, isToday: isToday))
                    .frame(width: 5, height: 5)
                    .opacity(hasTasks ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.cellHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: day, hasTasks: hasTasks))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func numberColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected { return AppTheme.colors.textOnTint }
        if isToday { return AppTheme.colors.tint }
        return AppTheme.colors.textPrimary
    }

    private func dotColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected { return AppTheme.colors.textOnTint }
        if isToday { return AppTheme.colors.tint }
        return AppTheme.colors.textSecondary
    }

    private func dayNumber(for date: Date) -> String {
        String(calendar.component(.day, from: date))
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let firstIndex = calendar.firstWeekday - 1
        guard symbols.indices.contains(firstIndex) else { return symbols }
        return Array(symbols[firstIndex...] + symbols[..<firstIndex])
    }

    private var weekCells: [Date] {
        let referenceDate = calendar.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month)
            ? selectedDate
            : displayedMonth

        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
            return []
        }

        var days: [Date] = []
        for offset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: offset, to: weekInterval.start) {
                days.append(calendar.startOfDay(for: day))
            }
        }
        return days
    }

    private var monthCells: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let leading = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)

        for offset in 0..<range.count {
            cells.append(calendar.date(byAdding: .day, value: offset, to: monthStart))
        }

        while cells.count % 7 != 0 {
            cells.append(nil)
        }

        return cells
    }

    private func changeMonth(by value: Int) {
        guard let shifted = calendar.date(byAdding: .month, value: value, to: displayedMonth),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: shifted)) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.18)) {
            displayedMonth = monthStart
            selectedDate = monthStart
        }
    }

    private func changeWeek(by value: Int) {
        guard let shifted = calendar.date(byAdding: .day, value: value * 7, to: selectedDate) else { return }
        let newDate = calendar.startOfDay(for: shifted)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedDate = newDate
            if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: newDate)) {
                displayedMonth = monthStart
            }
        }
    }

    private func accessibilityLabel(for date: Date, hasTasks: Bool) -> String {
        var label = Self.accessibilityFormatter.string(from: date)
        if calendar.isDateInToday(date) { label += ", today" }
        if hasTasks { label += ", has tasks" }
        return label
    }
}
