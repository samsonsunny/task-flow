import SwiftUI
import SwiftData

struct TaskListBucketScreenView: View {
    @Environment(\.modelContext) private var modelContext

    let bucket: TaskBucket
    let tasks: [TaskItem]
    @Binding var captureTitle: String
    @Binding var captureDueSelection: CaptureDueSelection?
    @Binding var isCaptureDatePickerPresented: Bool
    @Binding var captureChosenDate: Date
    @Binding var selectedDestination: SidebarDestination

    @FocusState var captureFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                TaskListHeaderView(
                    title: screenTitle(for: bucket),
                    subtitle: bucketSubtitle(for: bucket)
                )
                .listRowSeparator(.hidden)

                if bucket == .upcoming {
                    upcomingContent
                } else {
                    ForEach(TaskListLogic.filteredTasks(tasks, for: bucket)) { task in
                        taskListRow(task, in: bucket)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .animation(.easeInOut, value: TaskListLogic.filteredTasks(tasks, for: bucket).count)
            .animation(.easeInOut, value: selectedDestination)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .safeAreaInset(edge: .bottom) {
            TaskCaptureBarView(
                title: $captureTitle,
                dueSelection: $captureDueSelection,
                isDatePickerPresented: $isCaptureDatePickerPresented,
                chosenDate: $captureChosenDate,
                selectedBucket: bucket,
                onSubmit: submitFromCapture,
                captureFocused: $captureFocused
            )
        }
    }

    private var upcomingContent: some View {
        let upcomingTasks = TaskListLogic.filteredTasks(tasks, for: .upcoming)
        let sorted = TaskListLogic.sortUpcomingTasks(upcomingTasks)

        return TaskListUpcomingView(
            tasks: sorted,
            row: { task in AnyView(taskListRow(task, in: .upcoming)) }
        )
    }

    private func taskRow(_ task: TaskItem, in bucket: TaskBucket) -> some View {
        return TaskRowView(
            task: task,
            isCompletedVisualState: task.isCompleted == true,
            onToggleCompletion: { toggleCompletion(for: task) },
            onMoveToToday: bucket == .tomorrow || bucket == .upcoming || bucket == .someday ? { rescheduleTaskToToday(task) } : nil,
            onMoveToTomorrow: bucket == .today || bucket == .upcoming || bucket == .someday ? { rescheduleTaskToTomorrow(task) } : nil,
            onMoveToLater: bucket == .tomorrow ? { rescheduleTaskToLater(task) } : nil,
            onSchedule: nil
        )
    }

    private func taskListRow(_ task: TaskItem, in bucket: TaskBucket) -> some View {
        taskRow(task, in: bucket)
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    modelContext.delete(task)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    private func submitFromCapture() {
        let normalizedTitle = normalizedCaptureTitle(captureTitle)
        guard !normalizedTitle.isEmpty else { return }

        let task = TaskItem(taskTitle: normalizedTitle, dueDate: dueDateForCreate(in: bucket))
        modelContext.insert(task)

        captureTitle = ""
    }
}

private extension TaskListBucketScreenView {
    func normalizedCaptureTitle(_ rawTitle: String) -> String {
        let withSpacesForNewlines = rawTitle
            .components(separatedBy: .newlines)
            .joined(separator: " ")
        return withSpacesForNewlines.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func effectiveCaptureDueSelection(for bucket: TaskBucket) -> CaptureDueSelection {
        captureDueSelection ?? defaultCaptureDueSelection(for: bucket)
    }

    func defaultCaptureDueSelection(for bucket: TaskBucket) -> CaptureDueSelection {
        let calendar = Calendar.current
        switch bucket {
        case .today:
            return .today
        case .tomorrow:
            return .tomorrow
        case .someday:
            return .someday
        case .upcoming:
            let todayStart = calendar.startOfDay(for: Date())
            let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: todayStart) ?? todayStart
            return .chooseDay(dayAfterTomorrow)
        }
    }

    func dueDateForCreate(in bucket: TaskBucket) -> Date? {
        switch effectiveCaptureDueSelection(for: bucket) {
        case .today:
            return Date()
        case .tomorrow:
            return Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .someday:
            return nil
        case .chooseDay(let date):
            return Calendar.current.startOfDay(for: date)
        }
    }

    func toggleCompletion(for task: TaskItem) {
        withAnimation(.easeInOut(duration: 0.18)) {
            let next = !(task.isCompleted ?? false)
            task.isCompleted = next
            task.completionDate = next ? Date() : nil
        }
    }

    // Upcoming section expansion removed for MVP simplicity.

    func bucketSubtitle(for bucket: TaskBucket) -> String? {
        switch bucket {
        case .today:
            return TaskListView.tabDateFormatter.string(from: Date())
        case .tomorrow:
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            return TaskListView.tabDateFormatter.string(from: tomorrow)
        case .upcoming, .someday:
            return nil
        }
    }

    func screenTitle(for bucket: TaskBucket) -> String {
        switch bucket {
        case .today:
            return "Today"
        case .tomorrow:
            return "Tomorrow"
        case .upcoming:
            return "Upcoming"
        case .someday:
            return "Tasks"
        }
    }

    func rescheduleTaskToToday(_ task: TaskItem) {
        task.dueDate = Calendar.current.startOfDay(for: Date())
    }

    func rescheduleTaskToTomorrow(_ task: TaskItem) {
        let calendar = Calendar.current
        let referenceDate = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) else {
            return
        }
        task.dueDate = tomorrow
    }

    func rescheduleTaskToLater(_ task: TaskItem) {
        task.dueDate = nil
    }
}
