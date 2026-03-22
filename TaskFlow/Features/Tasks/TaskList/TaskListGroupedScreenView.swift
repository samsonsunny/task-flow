import SwiftUI
import SwiftData

struct TaskListGroupedScreenView: View {
    @Environment(\.modelContext) private var modelContext

    let tasks: [TaskItem]
    @Binding var captureTitle: String
    @Binding var captureDueSelection: CaptureDueSelection?
    @Binding var isCaptureDatePickerPresented: Bool
    @Binding var captureChosenDate: Date

    @FocusState private var captureFocused: Bool

    var body: some View {
        List {
            TaskListHeaderView(
                title: "TaskFlow",
                subtitle: nil
            )
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            bucketSection(.today, alwaysVisible: true, maxCount: nil, emptyText: "No tasks for today.")
            bucketSection(.tomorrow, alwaysVisible: true, maxCount: 5, emptyText: "No tasks for tomorrow yet.")
            bucketSection(.upcoming, alwaysVisible: true, maxCount: 5, emptyText: "No upcoming tasks yet.")
            bucketSection(.someday, alwaysVisible: false, maxCount: 5, emptyText: "No tasks in Later.")
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 12) {
            TaskCaptureBarView(
                title: $captureTitle,
                dueSelection: $captureDueSelection,
                isDatePickerPresented: $isCaptureDatePickerPresented,
                chosenDate: $captureChosenDate,
                selectedBucket: .today,
                onSubmit: submitFromCapture,
                captureFocused: $captureFocused
            )
        }
    }

    @ViewBuilder
    private func bucketSection(_ bucket: TaskBucket, alwaysVisible: Bool, maxCount: Int?, emptyText: String) -> some View {
        let bucketTasks = tasksForBucket(bucket)
        if alwaysVisible || !bucketTasks.isEmpty {
            Section {
                if bucketTasks.isEmpty {
                    Text(emptyText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(previewTasks(bucketTasks, maxCount: maxCount, bucket: bucket)) { task in
                        taskListRow(task, in: bucket)
                    }
                }
            } header: {
                sectionHeader(bucket: bucket, count: bucketTasks.count, maxCount: maxCount)
            }
        }
    }

    private func sectionHeader(bucket: TaskBucket, count: Int, maxCount: Int?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(bucket.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let subtitle = bucketSubtitle(for: bucket) {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let maxCount, count > maxCount {
                NavigationLink(value: bucket) {
                    Text("More")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .textCase(nil)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .padding(.horizontal, 16)
    }

    private func tasksForBucket(_ bucket: TaskBucket) -> [TaskItem] {
        if bucket == .upcoming {
            return TaskListLogic.sortUpcomingTasks(TaskListLogic.filteredTasks(tasks, for: .upcoming))
        }
        return TaskListLogic.filteredTasks(tasks, for: bucket)
    }

    private func previewTasks(_ tasks: [TaskItem], maxCount: Int?, bucket: TaskBucket) -> [TaskItem] {
        if bucket == .today {
            return tasks
        }
        guard let maxCount else { return tasks }
        return Array(tasks.prefix(maxCount))
    }

    private func taskRow(_ task: TaskItem, in bucket: TaskBucket) -> some View {
        TaskRowView(
            task: task,
            isCompletedVisualState: task.isCompleted == true,
            onToggleCompletion: { toggleCompletion(for: task) },
            onMoveToToday: bucket == .tomorrow || bucket == .upcoming || bucket == .someday ? { rescheduleTaskToToday(task) } : nil,
            onMoveToTomorrow: bucket == .today || bucket == .upcoming || bucket == .someday ? { rescheduleTaskToTomorrow(task) } : nil,
            onMoveToLater: bucket == .tomorrow ? { rescheduleTaskToLater(task) } : nil,
            onSchedule: nil,
            showsDueDate: bucket == .upcoming
        )
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

        let task = TaskItem(taskTitle: normalizedTitle, dueDate: dueDateForCreate())
        modelContext.insert(task)
        captureTitle = ""
    }
}

private extension TaskListGroupedScreenView {
    func normalizedCaptureTitle(_ rawTitle: String) -> String {
        let withSpacesForNewlines = rawTitle
            .components(separatedBy: .newlines)
            .joined(separator: " ")
        return withSpacesForNewlines.trimmingCharacters(in: .whitespacesAndNewlines)
}

    func effectiveCaptureDueSelection() -> CaptureDueSelection {
        captureDueSelection ?? .today
    }

    func dueDateForCreate() -> Date? {
        switch effectiveCaptureDueSelection() {
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
