import SwiftUI
import SwiftData

struct TaskListView: View {
    static var hasAppliedColdLaunchDefault = false

    @Environment(\.modelContext) var modelContext
    @Query(
        filter: #Predicate<TaskItem> { $0.isCompleted != true },
        sort: \TaskItem.createdAt,
        order: .reverse
    ) var tasks: [TaskItem]

    @State private var captureTitle = ""
    @State private var captureDueSelection: CaptureDueSelection?
    @State private var isCaptureDatePickerPresented = false
    @State private var captureChosenDate = Calendar.current.startOfDay(for: Date())

    var body: some View {
        NavigationStack {
            TaskListGroupedScreenView(
                tasks: tasks,
                captureTitle: $captureTitle,
                captureDueSelection: $captureDueSelection,
                isCaptureDatePickerPresented: $isCaptureDatePickerPresented,
                captureChosenDate: $captureChosenDate
            )
            .navigationDestination(for: TaskBucket.self) { bucket in
                TaskListBucketScreenView(
                    bucket: bucket,
                    tasks: tasks,
                    captureTitle: $captureTitle,
                    captureDueSelection: $captureDueSelection,
                    isCaptureDatePickerPresented: $isCaptureDatePickerPresented,
                    captureChosenDate: $captureChosenDate
                )
            }
        }
        .onAppear {
            applyDefaultCaptureDueSelectionForUpcomingIfNeeded()
        }
        .sheet(isPresented: $isCaptureDatePickerPresented) {
            TaskCaptureDatePickerSheet(
                isPresented: $isCaptureDatePickerPresented,
                chosenDate: $captureChosenDate,
                dueSelection: $captureDueSelection
            )
        }
    }

    private func applyDefaultCaptureDueSelectionForUpcomingIfNeeded() {
        guard captureDueSelection == nil else { return }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: todayStart) ?? todayStart
        captureChosenDate = dayAfterTomorrow
    }

    static let tabDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE MMM d")
        return formatter
    }()

    static let chipDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedTaskList(into: container)
    return TaskListView()
        .modelContainer(container)
}

#Preview("Empty State") {
    TaskListView()
        .modelContainer(for: [TaskItem.self], inMemory: true)
}
