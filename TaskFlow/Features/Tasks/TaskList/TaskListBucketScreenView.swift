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
    let captureFocused: FocusState<Bool>.Binding

    @State private var taskBeingScheduled: TaskItem?
    @State private var isTaskScheduleSheetPresented = false
    @State private var taskScheduleChosenDate = Calendar.current.startOfDay(for: Date())

    var body: some View {
        List {
            TaskListHeaderView(
                title: screenTitle(for: bucket),
                subtitle: bucketSubtitle(for: bucket)
            )
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            if bucket == .upcoming {
                upcomingContent
            } else {
                let bucketTasks = TaskListLogic.filteredTasks(tasks, for: bucket)
                if !bucketTasks.isEmpty {
                    ForEach(bucketTasks) { task in
                        taskListRow(task, in: bucket)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .animation(.easeInOut, value: TaskListLogic.filteredTasks(tasks, for: bucket).count)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { TaskCaptureBottomBarToolbar(title: $captureTitle, onSubmit: submitFromCapture, captureFocused: captureFocused) }
        .sheet(isPresented: $isTaskScheduleSheetPresented) {
            TaskScheduleDatePickerSheet(
                isPresented: $isTaskScheduleSheetPresented,
                chosenDate: $taskScheduleChosenDate,
                onChooseDate: { chosen in
                    taskBeingScheduled?.dueDate = chosen
                }
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
        TaskRowView(
            task: task,
            isCompletedVisualState: task.isCompleted == true,
            onToggleCompletion: { toggleCompletion(for: task) },
            onMoveToToday: bucket == .tomorrow || bucket == .upcoming || bucket == .someday ? { rescheduleTaskToToday(task) } : nil,
            onMoveToTomorrow: bucket == .today || bucket == .upcoming || bucket == .someday ? { rescheduleTaskToTomorrow(task) } : nil,
            onMoveToLater: bucket == .tomorrow ? { rescheduleTaskToLater(task) } : nil,
            onSchedule: { presentScheduleSheet(for: task) },
            showsDueDate: bucket == .upcoming
        )
    }

    private func presentScheduleSheet(for task: TaskItem) {
        taskBeingScheduled = task
        taskScheduleChosenDate = Calendar.current.startOfDay(for: task.dueDate ?? Date())
        isTaskScheduleSheetPresented = true
    }

    private func taskListRow(_ task: TaskItem, in bucket: TaskBucket) -> some View {
        taskRow(task, in: bucket)
            .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
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
        captureDueSelection = nil
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
        case .upcoming:
            return nil
        case .someday:
            return "No date set"
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
            return "Later"
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
