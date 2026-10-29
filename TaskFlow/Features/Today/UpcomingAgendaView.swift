import SwiftUI
import SwiftData

struct UpcomingDaySection: Identifiable {
    let date: Date
    let tasks: [TaskItem]

    var id: Date { date }
}

private struct AgendaSectionTopKey: PreferenceKey {
    static var defaultValue: [Date: CGFloat] = [:]
    static func reduce(value: inout [Date: CGFloat], nextValue: () -> [Date: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// Vertically scrolling week agenda. Each day of the selected week stays visible,
/// even when it has no tasks, and the selected date is kept in sync with the
/// week strip above it.
struct UpcomingAgendaView: View {
    let sections: [UpcomingDaySection]
    @Binding var selectedDate: Date
    let scrollRequestToken: Int
    let dayTapToken: Int
    let dayTapDate: Date
    let scrollController: ScrollAnimationController
    let onAddTask: (Date) -> Void
    let onToggleCompletion: (TaskItem) -> Void
    let onDelete: (TaskItem) -> Void
    let onTapTask: (TaskItem) -> Void
    let onRefresh: () -> Void

    @State private var sectionTops: [Date: CGFloat] = [:]
    @State private var isUserScrolling = false
    @State private var isScrollDrivenSelection = false
    @State private var lastScrollTop: CGFloat = 0
    @State private var hasPerformedInitialScroll = false
    @State private var pendingExactScrollDate: Date?

    private let calendar = Calendar.current

    init(
        sections: [UpcomingDaySection],
        selectedDate: Binding<Date>,
        scrollRequestToken: Int,
        dayTapToken: Int,
        dayTapDate: Date,
        scrollController: ScrollAnimationController,
        onAddTask: @escaping (Date) -> Void,
        onToggleCompletion: @escaping (TaskItem) -> Void,
        onDelete: @escaping (TaskItem) -> Void,
        onTapTask: @escaping (TaskItem) -> Void,
        onRefresh: @escaping () -> Void
    ) {
        self.sections = sections
        self._selectedDate = selectedDate
        self.scrollRequestToken = scrollRequestToken
        self.dayTapToken = dayTapToken
        self.dayTapDate = dayTapDate
        self.scrollController = scrollController
        self.onAddTask = onAddTask
        self.onToggleCompletion = onToggleCompletion
        self.onDelete = onDelete
        self.onTapTask = onTapTask
        self.onRefresh = onRefresh
    }

    private static let headingFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE, d")
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
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(sections) { section in
                        daySection(section)
                            .id(section.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.top, 2)
                .padding(.bottom, 100)
                .coordinateSpace(.named("agendaContent"))
                .onPreferenceChange(AgendaSectionTopKey.self) { handleSectionTops($0) }
                .background(ScrollViewLocator(controller: scrollController))
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
            .onAppear {
                guard !hasPerformedInitialScroll else { return }
                hasPerformedInitialScroll = true
                scrollToInitialPosition(proxy: proxy)
            }
            .refreshable { onRefresh() }
            .onChange(of: selectedDate) { _, newValue in
                if isScrollDrivenSelection {
                    isScrollDrivenSelection = false
                    return
                }

                scrollAgenda(to: newValue, proxy: proxy)
            }
            .onChange(of: scrollRequestToken) { _, _ in
                scrollAgenda(to: calendar.startOfDay(for: Date()), proxy: proxy)
            }
            .onChange(of: dayTapToken) { _, _ in
                let day = calendar.startOfDay(for: dayTapDate)
                isUserScrolling = false
                if calendar.startOfDay(for: selectedDate) != day {
                    isScrollDrivenSelection = true
                    selectedDate = day
                }
                scrollAgenda(to: day, proxy: proxy, animated: false)
            }
        }
    }

    private func scrollToInitialPosition(proxy: ScrollViewProxy) {
        for delay in [0.0, 0.12] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let day = calendar.startOfDay(for: selectedDate)
                isUserScrolling = false
                scrollController.halt()
                proxy.scrollTo(day, anchor: .top)
            }
        }
    }

    private func scrollAgenda(to date: Date, proxy: ScrollViewProxy, animated: Bool = true) {
        let day = calendar.startOfDay(for: date)
        isUserScrolling = false
        scrollController.halt()
        setExactOffset(for: day, animated: animated, proxy: proxy)
    }

    private func setExactOffset(for day: Date, animated: Bool, proxy: ScrollViewProxy) {
        guard let scrollView = scrollController.scrollView else {
            pendingExactScrollDate = day
            proxy.scrollTo(day, anchor: .top)
            return
        }

        guard let top = sectionTops[day] else {
            pendingExactScrollDate = day
            proxy.scrollTo(day, anchor: .top)
            return
        }

        applyOffset(top, in: scrollView, animated: animated)
        pendingExactScrollDate = nil
    }

    private func handleSectionTops(_ tops: [Date: CGFloat]) {
        sectionTops = tops
        guard let pending = pendingExactScrollDate,
              let top = tops[pending],
              let scrollView = scrollController.scrollView else { return }
        pendingExactScrollDate = nil
        applyOffset(top, in: scrollView, animated: false)
    }

    private func applyOffset(_ top: CGFloat, in scrollView: UIScrollView, animated: Bool) {
        let insetTop = scrollView.adjustedContentInset.top
        let maxY = scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
        let y = min(max(-insetTop, top - insetTop), maxY)
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: y), animated: animated)
        lastScrollTop = top
    }

    private func updateSelectionForScroll(top: CGFloat) {
        guard let date = sectionTops
            .filter({ $0.value <= top + 1 })
            .max(by: { $0.value < $1.value })?
            .key else { return }
        let day = calendar.startOfDay(for: date)
        guard selectedDate != day else { return }
        Haptics.selection()
        isScrollDrivenSelection = true
        selectedDate = day
    }

    @ViewBuilder
    private func daySection(_ section: UpcomingDaySection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                let calendar = Calendar.current
                let isToday = calendar.isDateInToday(section.date)
                let isTomorrow = calendar.isDateInTomorrow(section.date)
                let isYesterday = calendar.isDateInYesterday(section.date)
                let dateText = Self.headingFormatter.string(from: section.date)
                let headingText = isToday ? "\(dateText) · Today" : isTomorrow ? "\(dateText) · Tomorrow" : isYesterday ? "\(dateText) · Yesterday" : dateText
                Text(headingText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                Button {
                    Haptics.impact(.light)
                    onAddTask(section.date)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.colors.tint)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add task on \(isToday ? "Today" : isTomorrow ? "Tomorrow" : isYesterday ? "Yesterday" : Self.accessibilityFormatter.string(from: section.date))")
            }
            .padding(.horizontal, 20)

            if section.tasks.isEmpty {
                let calendar = Calendar.current
                let isToday = calendar.isDateInToday(section.date)
                let isTomorrow = calendar.isDateInTomorrow(section.date)
                let isYesterday = calendar.isDateInYesterday(section.date)
                Button {
                    Haptics.impact(.light)
                    onAddTask(section.date)
                } label: {
                    Text("No tasks scheduled")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.colors.textTertiary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
                .accessibilityLabel("Add task on \(isToday ? "Today" : isTomorrow ? "Tomorrow" : isYesterday ? "Yesterday" : Self.accessibilityFormatter.string(from: section.date))")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(section.tasks.enumerated()), id: \.element.id) { index, task in
                        let calendar = Calendar.current
                        let now = Date()
                        let todayStart = calendar.startOfDay(for: now)
                        let isOverdueTask: Bool = {
                            guard let dueDate = task.dueDate, !(task.isCompleted ?? false) else { return false }
                            if task.hasTime == true {
                                return dueDate < now
                            } else {
                                return calendar.startOfDay(for: dueDate) < todayStart
                            }
                        }()
                        TaskRowView(
                            task: task,
                            isCompletedVisualState: task.isCompleted ?? false,
                            onToggleCompletion: {
                                Haptics.impact(.light)
                                onToggleCompletion(task)
                            },
                            onDelete: { onDelete(task) },
                            onTap: { onTapTask(task) },
                            showsDueDate: isOverdueTask,
                            showsListName: true,
                            showsRowBackground: false
                        )

                        if index < section.tasks.count - 1 {
                            Divider()
                                .padding(.leading, 54)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous))
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 20)
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: AgendaSectionTopKey.self,
                    value: [section.date: proxy.frame(in: .named("agendaContent")).minY]
                )
            }
        )
    }
}
