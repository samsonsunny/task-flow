import SwiftUI
import SwiftData

struct UpcomingDaySection: Identifiable {
    let date: Date
    let tasks: [TaskItem]

    var id: Date { date }
}

/// Vertically scrolling week agenda. Each day of the selected week stays visible,
/// even when it has no tasks, and the selected date is kept in sync with the
/// week strip above it.
struct UpcomingAgendaView: View {
    let sections: [UpcomingDaySection]
    @Binding var selectedDate: Date
    let onAddTask: (Date) -> Void
    let onToggleCompletion: (TaskItem) -> Void
    let onDelete: (TaskItem) -> Void
    let onTapTask: (TaskItem) -> Void
    let onRefresh: () -> Void

    @State private var scrollPosition: Date?
    @State private var isProgrammaticScroll = false
    @State private var isScrollDrivenSelection = false

    private let calendar = Calendar.current

    init(
        sections: [UpcomingDaySection],
        selectedDate: Binding<Date>,
        onAddTask: @escaping (Date) -> Void,
        onToggleCompletion: @escaping (TaskItem) -> Void,
        onDelete: @escaping (TaskItem) -> Void,
        onTapTask: @escaping (TaskItem) -> Void,
        onRefresh: @escaping () -> Void
    ) {
        self.sections = sections
        self._selectedDate = selectedDate
        self.onAddTask = onAddTask
        self.onToggleCompletion = onToggleCompletion
        self.onDelete = onDelete
        self.onTapTask = onTapTask
        self.onRefresh = onRefresh
        _scrollPosition = State(initialValue: Calendar.current.startOfDay(for: selectedDate.wrappedValue))
    }

    private static let headingFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
        return formatter
    }()
    
    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
        return formatter
    }()

    var body: some View {
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
        }
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrollPosition, anchor: .top)
        .refreshable { onRefresh() }
        .onChange(of: selectedDate) { _, newValue in
            if isScrollDrivenSelection {
                isScrollDrivenSelection = false
                return
            }

            let day = calendar.startOfDay(for: newValue)
            guard scrollPosition != day else { return }

            isProgrammaticScroll = true
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollPosition = day
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isProgrammaticScroll = false
            }
        }
        .onChange(of: scrollPosition) { _, newValue in
            guard !isProgrammaticScroll, let date = newValue else { return }
            let day = calendar.startOfDay(for: date)
            guard selectedDate != day else { return }
            Haptics.selection()
            isScrollDrivenSelection = true
            selectedDate = day
        }
    }

    @ViewBuilder
    private func daySection(_ section: UpcomingDaySection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                let calendar = Calendar.current
                let isToday = calendar.isDateInToday(section.date)
                let isTomorrow = calendar.isDateInTomorrow(section.date)
                let dateText = Self.headingFormatter.string(from: section.date)
                let headingText = isToday ? "Today · \(dateText)" : isTomorrow ? "Tomorrow · \(dateText)" : dateText
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
                .accessibilityLabel("Add task on \(isToday ? "Today" : isTomorrow ? "Tomorrow" : Self.accessibilityFormatter.string(from: section.date))")
            }
            .padding(.horizontal, 20)

            if section.tasks.isEmpty {
                let calendar = Calendar.current
                let isToday = calendar.isDateInToday(section.date)
                let isTomorrow = calendar.isDateInTomorrow(section.date)
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
                .accessibilityLabel("Add task on \(isToday ? "Today" : isTomorrow ? "Tomorrow" : Self.accessibilityFormatter.string(from: section.date))")
            } else {
                VStack(spacing: 2) {
                    ForEach(section.tasks) { task in
                        TaskRowView(
                            task: task,
                            isCompletedVisualState: task.isCompleted ?? false,
                            onToggleCompletion: {
                                Haptics.impact(.light)
                                onToggleCompletion(task)
                            },
                            onDelete: { onDelete(task) },
                            onTap: { onTapTask(task) },
                            showsDueDate: false,
                            showsListName: true
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}
