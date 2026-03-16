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

    // Removed upcoming expand/collapse UI state for MVP simplicity.

    @State var selectedDestination: SidebarDestination = .bucket(.today)
    @State var didInitializeDestinationSelection = false
    @State var splitViewVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $splitViewVisibility) {
            TaskListSidebarView(
                selectedDestination: $selectedDestination,
                splitViewVisibility: $splitViewVisibility
            )
        } detail: {
            ZStack(alignment: .bottomTrailing) {
                destinationDetail
            }
        }
        .onAppear {
            initializeDestinationSelectionIfNeeded()
            applyDefaultCaptureDueSelectionForCurrentDestination()
        }
        .onChange(of: selectedDestination) { _, destination in
            applyDefaultCaptureDueSelectionForCurrentDestination()
        }
        .sheet(isPresented: $isCaptureDatePickerPresented) {
            TaskCaptureDatePickerSheet(
                isPresented: $isCaptureDatePickerPresented,
                chosenDate: $captureChosenDate,
                dueSelection: $captureDueSelection
            )
        }
    }

    @ViewBuilder
    private var destinationDetail: some View {
        switch selectedDestination {
        case .bucket(let bucket):
            TaskListBucketScreenView(
                bucket: bucket,
                tasks: tasks,
                captureTitle: $captureTitle,
                captureDueSelection: $captureDueSelection,
                isCaptureDatePickerPresented: $isCaptureDatePickerPresented,
                captureChosenDate: $captureChosenDate,
                selectedDestination: $selectedDestination
            )
        }
    }

    private var selectedBucketForCapture: TaskBucket {
        if case .bucket(let bucket) = selectedDestination {
            return bucket
        }
        return .today
    }

    private func applyDefaultCaptureDueSelectionForCurrentDestination() {
        captureDueSelection = nil
        if selectedBucketForCapture == .upcoming {
            let calendar = Calendar.current
            let todayStart = calendar.startOfDay(for: Date())
            let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: todayStart) ?? todayStart
            captureChosenDate = dayAfterTomorrow
        }
    }

    private func initializeDestinationSelectionIfNeeded() {
        guard !didInitializeDestinationSelection else { return }
        defer { didInitializeDestinationSelection = true }

        if Self.hasAppliedColdLaunchDefault {
            selectedDestination = .bucket(.today)
        } else {
            selectedDestination = .bucket(.today)
            Self.hasAppliedColdLaunchDefault = true
        }
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
