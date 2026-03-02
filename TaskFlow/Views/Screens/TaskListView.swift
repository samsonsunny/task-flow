//
//  TaskListView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI
import SwiftData

struct TaskListView: View {
    private enum TaskBucket: String, CaseIterable, Identifiable {
        case today
        case tomorrow
        case upcoming = "later"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .today: return "Today"
            case .tomorrow: return "Tomorrow"
            case .upcoming: return "Upcoming"
            }
        }
        
        var iconName: String {
            switch self {
            case .today: return "sun.max"
            case .tomorrow: return "calendar"
            case .upcoming: return "tray.full"
            }
        }
    }

    private enum CaptureMetrics {
        static let bottomInset: CGFloat = 10
        static let horizontalScreenInset: CGFloat = 16
        static let inputMinHeight: CGFloat = 54
        static let inputVerticalPadding: CGFloat = 15
        static let inputHorizontalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 16
        static let containerVerticalPadding: CGFloat = 8
    }
    
    private static var hasAppliedColdLaunchDefault = false

    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<TaskItem> { $0.isCompleted != true },
        sort: \TaskItem.createdAt,
        order: .reverse
    ) private var tasks: [TaskItem]
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var captureSession = CaptureSessionState()
    @State private var selectedBucket: TaskBucket = .today
    @State private var didInitializeTabSelection = false
    @State private var isCaptureBarVisible = false
    @State private var newTaskTitle = ""
    @State private var pendingCompletionTaskKeys: Set<String> = []
    @State private var completionWorkItems: [String: DispatchWorkItem] = [:]
    @FocusState private var captureFocused: Bool
    @SceneStorage("tasklist.selectedBucket") private var sceneSelectedBucketRaw = TaskBucket.today.rawValue
    @AppStorage("tasklist.lastOpenedBucket") private var lastOpenedBucketRaw = TaskBucket.today.rawValue

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedBucket) {
                bucketScreen(for: .today)
                    .tag(TaskBucket.today)
                    .tabItem {
                        Label(TaskBucket.today.title, systemImage: TaskBucket.today.iconName)
                    }
                bucketScreen(for: .tomorrow)
                    .tag(TaskBucket.tomorrow)
                    .tabItem {
                        Label(TaskBucket.tomorrow.title, systemImage: TaskBucket.tomorrow.iconName)
                    }
                bucketScreen(for: .upcoming)
                    .tag(TaskBucket.upcoming)
                    .tabItem {
                        Label(TaskBucket.upcoming.title, systemImage: TaskBucket.upcoming.iconName)
                    }
            }
            .onAppear {
                initializeTabSelectionIfNeeded()
                updateFocusIfNeeded()
            }
            .onChange(of: scenePhase) { phase in
                captureSession.handleScenePhase(phase)
                if phase == .active {
                    updateFocusIfNeeded()
                }
            }
            .onChange(of: captureFocused) { focused in
                if focused {
                    captureSession.recordFocused()
                } else if scenePhase == .active {
                    captureSession.markKeyboardDismissed()
                    hideCaptureBar()
                }
            }
            .onChange(of: newTaskTitle) { value in
                if hasTrailingNewline(value) {
                    newTaskTitle = value.trimmingTrailingNewlines()
                    submitFromKeyboard()
                    return
                }
                if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    captureSession.markTypedInSession()
                }
            }
            .onChange(of: selectedBucket) { bucket in
                sceneSelectedBucketRaw = bucket.rawValue
                lastOpenedBucketRaw = bucket.rawValue
            }

            if !isCaptureBarVisible {
                floatingAddButton
                    .padding(.trailing, AppTheme.spacing.lg)
                    .padding(.bottom, 84)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    private func bucketScreen(for bucket: TaskBucket) -> some View {
        NavigationStack {
            ZStack {
                AppTheme.colors.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    List {
                        Section(header: headerView(for: bucket)) {
                            ForEach(filteredTasks(for: bucket)) { task in
                                taskRow(task, in: bucket)
                                    .listRowInsets(
                                        EdgeInsets(
                                            top: AppTheme.spacing.xxs,
                                            leading: AppTheme.spacing.md,
                                            bottom: AppTheme.spacing.xxs,
                                            trailing: AppTheme.spacing.md
                                        )
                                    )
                                    .listRowBackground(AppTheme.colors.appBackground)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteTask(task)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .scrollDismissesKeyboard(.interactively)
                .animation(.easeInOut, value: filteredTasks(for: bucket).count)
                .animation(.easeInOut, value: selectedBucket)
                .simultaneousGesture(
                    DragGesture().onChanged { _ in
                        captureSession.markScrolledBeforeTyping()
                        hideCaptureBar()
                    }
                )
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if isCaptureBarVisible {
                    captureBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: isCaptureBarVisible)
        }
    }
    
    private func taskRow(_ task: TaskItem, in bucket: TaskBucket) -> some View {
        let key = taskKey(for: task)
        return TaskRowView(
            task: task,
            isCompletedVisualState: pendingCompletionTaskKeys.contains(key),
            onToggleCompletion: {
                toggleCompletion(for: task)
            },
            onMoveToToday: bucket == .tomorrow || bucket == .upcoming ? { rescheduleTaskToToday(task) } : nil,
            onMoveToTomorrow: bucket == .today || bucket == .upcoming ? { rescheduleTaskToTomorrow(task) } : nil,
            onMoveToLater: bucket == .tomorrow ? { rescheduleTaskToLater(task) } : nil
        )
    }

        private func rescheduleTaskToToday(_ task: TaskItem) {
        task.dueDate = Calendar.current.startOfDay(for: Date())
    }

    private func rescheduleTaskToTomorrow(_ task: TaskItem) {
        let calendar = Calendar.current
        let referenceDate = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) else {
            return
        }
        task.dueDate = tomorrow
    }

    private func rescheduleTaskToLater(_ task: TaskItem) {
        task.dueDate = nil
    }
    
    private func createTask(title: String) {
        let normalizedTitle = normalizedCaptureTitle(title)
        guard !normalizedTitle.isEmpty else { return }

        let task = TaskItem(
            taskTitle: normalizedTitle,
            dueDate: dueDateForCreate(in: selectedBucket)
        )
        modelContext.insert(task)
        captureSession.recordTaskAdded()
    }

    private func deleteTask(_ task: TaskItem) {
        cancelPendingCompletion(for: taskKey(for: task))
        modelContext.delete(task)
    }

    private func toggleCompletion(for task: TaskItem) {
        let key = taskKey(for: task)
        if pendingCompletionTaskKeys.contains(key) {
            cancelPendingCompletion(for: key)
            return
        }

        pendingCompletionTaskKeys.insert(key)

        let workItem = DispatchWorkItem {
            finalizeCompletion(for: task, key: key)
        }
        completionWorkItems[key] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: workItem)
    }

    private func finalizeCompletion(for task: TaskItem, key: String) {
        guard pendingCompletionTaskKeys.contains(key) else { return }
        completionWorkItems[key] = nil
        withAnimation(.easeInOut(duration: 0.22)) {
            pendingCompletionTaskKeys.remove(key)
            task.isCompleted = true
            task.completionDate = Date()
        }
    }

    private func cancelPendingCompletion(for key: String) {
        completionWorkItems[key]?.cancel()
        completionWorkItems[key] = nil
        withAnimation(.easeInOut(duration: 0.14)) {
            pendingCompletionTaskKeys.remove(key)
        }
    }

    private func taskKey(for task: TaskItem) -> String {
        if let taskId = task.taskId, !taskId.isEmpty {
            return taskId
        }
        return String(describing: task.persistentModelID)
    }

    private var captureBar: some View {
        VStack(spacing: .zero) {
            ZStack(alignment: .topLeading) {
                if newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("What's on your mind?")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(AppTheme.colors.textDisabled)
                }

                TextField("", text: $newTaskTitle, axis: .vertical)
                    .submitLabel(.done)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppTheme.colors.textPrimary)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .multilineTextAlignment(.leading)
                    .focused($captureFocused)
                    .onSubmit {
                        submitFromKeyboard()
                    }
            }
            .padding(.vertical, CaptureMetrics.inputVerticalPadding)
            .padding(.horizontal, CaptureMetrics.inputHorizontalPadding)
            .frame(minHeight: CaptureMetrics.inputMinHeight)
            .background(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: CaptureMetrics.cornerRadius)
                    .stroke(AppTheme.colors.border.opacity(0.7), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: CaptureMetrics.cornerRadius))
        }
        .padding(.vertical, CaptureMetrics.containerVerticalPadding)
        .padding(.horizontal, CaptureMetrics.horizontalScreenInset)
        .padding(.bottom, CaptureMetrics.bottomInset)
        .background(AppTheme.colors.appBackground)
    }

    private func updateFocusIfNeeded() {
        guard isCaptureBarVisible else { return }
        if captureSession.shouldAutoFocus(isListEmpty: filteredTasks(for: selectedBucket).isEmpty) {
            captureFocused = true
        }
    }

    private func submitFromKeyboard() {
        let normalizedTitle = normalizedCaptureTitle(newTaskTitle)
        guard !normalizedTitle.isEmpty else { return }

        createTask(title: normalizedTitle)
        newTaskTitle = ""
        captureFocused = true
    }

    private func toggleCaptureBar() {
        if isCaptureBarVisible {
            hideCaptureBar()
            return
        }
        withAnimation(.easeInOut(duration: 0.22)) {
            isCaptureBarVisible = true
        }
        DispatchQueue.main.async {
            captureFocused = true
        }
    }

    private func hideCaptureBar() {
        guard isCaptureBarVisible else { return }
        captureFocused = false
        withAnimation(.easeInOut(duration: 0.22)) {
            isCaptureBarVisible = false
        }
    }
    
    private var floatingAddButton: some View {
        Button {
            toggleCaptureBar()
        } label: {
            ZStack {
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.colors.border.opacity(0.6), lineWidth: 0.8)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add Task")
        .padding(.top, AppTheme.spacing.sm)
    }

    private func normalizedCaptureTitle(_ rawTitle: String) -> String {
        let withSpacesForNewlines = rawTitle
            .components(separatedBy: .newlines)
            .joined(separator: " ")
        return withSpacesForNewlines.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func hasTrailingNewline(_ value: String) -> Bool {
        value.last?.isNewline == true
    }
    
    private func filteredTasks(for bucket: TaskBucket) -> [TaskItem] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let dueDate = task.dueDate else {
                return bucket == .upcoming
            }
            switch bucket {
            case .today:
                return calendar.isDateInToday(dueDate)
            case .tomorrow:
                return calendar.isDateInTomorrow(dueDate)
            case .upcoming:
                return !calendar.isDateInToday(dueDate) && !calendar.isDateInTomorrow(dueDate)
            }
        }
    }
    
    private func bucketSubtitle(for bucket: TaskBucket) -> String? {
        switch bucket {
        case .today:
            return Self.tabDateFormatter.string(from: Date())
        case .tomorrow:
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            return Self.tabDateFormatter.string(from: tomorrow)
        case .upcoming:
            return nil
        }
    }
    
    private func headerView(for bucket: TaskBucket) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(screenTitle(for: bucket))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.colors.textPrimary)
            if let subtitle = bucketSubtitle(for: bucket) {
                Text(subtitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.textPrimary.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.spacing.md)
        .padding(.top, AppTheme.spacing.lg)
        .padding(.bottom, AppTheme.spacing.sm)
    }
    
    private func screenTitle(for bucket: TaskBucket) -> String {
        switch bucket {
        case .today:
            return "Today"
        case .tomorrow:
            return "Tomorrow"
        case .upcoming:
            return "Tasks"
        }
    }
    
    private func dueDateForCreate(in bucket: TaskBucket) -> Date? {
        switch bucket {
        case .today:
            return Date()
        case .tomorrow:
            return Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .upcoming:
            return nil
        }
    }
    
    private func initializeTabSelectionIfNeeded() {
        guard !didInitializeTabSelection else { return }
        defer { didInitializeTabSelection = true }
        
        if Self.hasAppliedColdLaunchDefault {
            if let restoredBucket = TaskBucket(rawValue: sceneSelectedBucketRaw) {
                selectedBucket = restoredBucket
            } else if let persistedBucket = TaskBucket(rawValue: lastOpenedBucketRaw) {
                selectedBucket = persistedBucket
            } else {
                selectedBucket = .today
            }
        } else {
            selectedBucket = defaultBucketForCurrentTime()
            Self.hasAppliedColdLaunchDefault = true
        }
        sceneSelectedBucketRaw = selectedBucket.rawValue
        lastOpenedBucketRaw = selectedBucket.rawValue
    }
    
    private func defaultBucketForCurrentTime(now: Date = Date()) -> TaskBucket {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        return hour >= 20 ? .tomorrow : .today
    }
    
    private static let tabDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE MMM d")
        return formatter
    }()

}

private extension String {
    func trimmingTrailingNewlines() -> String {
        var result = self
        while result.last?.isNewline == true {
            result.removeLast()
        }
        return result
    }
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
