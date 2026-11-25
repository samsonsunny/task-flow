import SwiftUI

struct ScheduledDaySection: Identifiable {
    let date: Date
    let tasks: [TaskItem]

    var id: Date { date }
}

private struct ScheduledSectionTopKey: PreferenceKey {
    static var defaultValue: [Date: CGFloat] = [:]
    static func reduce(value: inout [Date: CGFloat], nextValue: () -> [Date: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// Tasks grouped by the day they are due, listed chronologically.
struct ScheduledTaskListView: View {
    let sections: [ScheduledDaySection]
    @Binding var selectedDate: Date
    let scrollRequestToken: Int
    let actions: TaskRowActions
    let onRefresh: () -> Void

    @State private var sectionTops: [Date: CGFloat] = [:]
    @State private var isUserScrolling = false
    @State private var isScrollDrivenSelection = false
    @State private var lastScrollTop: CGFloat = 0
    @State private var scrollTaskWorkItem: DispatchWorkItem?

    private let calendar = Calendar.current

    private static let headingFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
        return formatter
    }()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if sections.isEmpty {
                    emptyState
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, 100)
                } else {
                    LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                        ForEach(sections) { section in
                            daySection(section)
                                .id(section.date)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.xs)
                    .padding(.bottom, 100)
                    .coordinateSpace(.named("scheduledContent"))
                    .onPreferenceChange(ScheduledSectionTopKey.self) { sectionTops = $0 }
                }
            }
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, top in
                lastScrollTop = top
                if isUserScrolling {
                    updateSelectionForScroll(top: top)
                }
            }
            .onScrollPhaseChange { _, newPhase in
                switch newPhase {
                case .tracking, .interacting, .decelerating:
                    isUserScrolling = true
                case .idle:
                    if isUserScrolling {
                        updateSelectionForScroll(top: lastScrollTop)
                    }
                    isUserScrolling = false
                case .animating:
                    isUserScrolling = false
                }
            }
            .refreshable { onRefresh() }
            .onAppear {
                scrollToSelectedDate(proxy: proxy, animated: false)
            }
            .onChange(of: scrollRequestToken) { _, _ in
                isUserScrolling = false
                scrollToSelectedDate(proxy: proxy, animated: true)
            }
        }
    }

    private func updateSelectionForScroll(top: CGFloat) {
        guard let date = sectionTops
            .filter({ $0.value <= top + 20 })
            .max(by: { $0.value < $1.value })?
            .key else { return }
        let day = calendar.startOfDay(for: date)
        guard selectedDate != day else { return }
        Haptics.selection()
        isScrollDrivenSelection = true
        selectedDate = day
    }

    private func scrollToSelectedDate(proxy: ScrollViewProxy, animated: Bool = true) {
        scrollTaskWorkItem?.cancel()

        let day = calendar.startOfDay(for: selectedDate)
        let targetDate: Date? = {
            if sections.contains(where: { $0.date == day }) {
                return day
            }
            // If the exact selected date has no tasks, scroll to the nearest following section or the last section
            return sections.first(where: { $0.date >= day })?.date ?? sections.last?.date
        }()

        guard let targetDate else { return }

        let workItem = DispatchWorkItem {
            if animated {
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(targetDate, anchor: .top)
                }
            } else {
                proxy.scrollTo(targetDate, anchor: .top)
            }
        }
        scrollTaskWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No scheduled tasks",
            systemImage: "calendar.badge.plus",
            description: Text("Tasks with a date this month will appear here.")
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    private func daySection(_ section: ScheduledDaySection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(headingText(for: section.date))
                .font(AppFont.subheadlineSemibold)
                .foregroundStyle(AppTheme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            VStack(spacing: 0) {
                ForEach(Array(section.tasks.enumerated()), id: \.element.id) { index, task in
                    TaskRowView(
                        task: task,
                        actions: actions,
                        showsDueDate: false,
                        enablesFallbackSwipe: true
                    )

                    if index < section.tasks.count - 1 {
                        Divider()
                            .padding(.leading, 54)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(AppColors.groupedSurface)
            )
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ScheduledSectionTopKey.self,
                    value: [section.date: proxy.frame(in: .named("scheduledContent")).minY]
                )
            }
        )
    }

    private func headingText(for date: Date) -> String {
        let dateText = Self.headingFormatter.string(from: date)
        if calendar.isDateInToday(date) { return "\(dateText) · Today" }
        if calendar.isDateInTomorrow(date) { return "\(dateText) · Tomorrow" }
        if calendar.isDateInYesterday(date) { return "\(dateText) · Yesterday" }
        return dateText
    }
}
