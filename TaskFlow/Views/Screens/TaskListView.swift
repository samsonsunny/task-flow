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

    private enum UpcomingSection: String, CaseIterable, Identifiable, Hashable {
        case thisWeek
        case nextWeek
        case later
        case unscheduled

        var id: String { rawValue }

        var title: String {
            switch self {
            case .thisWeek: return "This Week"
            case .nextWeek: return "Next Week"
            case .later: return "Later"
            case .unscheduled: return "Unscheduled"
            }
        }

        var isExpandedByDefault: Bool {
            self == .thisWeek
        }

    }

    private struct UpcomingSectionGroup: Identifiable {
        let section: UpcomingSection
        let tasks: [TaskItem]

        var id: String { section.rawValue }
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
    @State private var upcomingSectionExpansionOverrides: [UpcomingSection: Bool] = [:]
    @State private var schedulingTask: TaskItem?
    @State private var schedulingDate = Calendar.current.startOfDay(for: Date())
    @State private var isScheduleSheetPresented = false
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
            .onChange(of: scenePhase) { _, phase in
                captureSession.handleScenePhase(phase)
                if phase == .active {
                    updateFocusIfNeeded()
                }
            }
            .onChange(of: captureFocused) { _, focused in
                if focused {
                    captureSession.recordFocused()
                } else if scenePhase == .active {
                    captureSession.markKeyboardDismissed()
                    hideCaptureBar()
                }
            }
            .onChange(of: newTaskTitle) { _, value in
                if hasTrailingNewline(value) {
                    newTaskTitle = value.trimmingTrailingNewlines()
                    submitFromKeyboard()
                    return
                }
                if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    captureSession.markTypedInSession()
                }
            }
            .onChange(of: selectedBucket) { _, bucket in
                sceneSelectedBucketRaw = bucket.rawValue
                lastOpenedBucketRaw = bucket.rawValue
            }
            .onAppear {
                synchronizeUpcomingSectionVisibilityState()
            }
            .onChange(of: upcomingVisibilitySignature) { _, _ in
                synchronizeUpcomingSectionVisibilityState()
            }

            if !isCaptureBarVisible {
                floatingAddButton
                    .padding(.trailing, AppTheme.spacing.lg)
                    .padding(.bottom, 84)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $isScheduleSheetPresented, onDismiss: {
            schedulingTask = nil
        }) {
            scheduleSheet
        }
    }
    private func bucketScreen(for bucket: TaskBucket) -> some View {
        NavigationStack {
            ZStack {
                AppTheme.colors.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    List {
                        headerView(for: bucket)
                            .listRowInsets(
                                EdgeInsets(
                                    top: .zero,
                                    leading: AppTheme.spacing.md,
                                    bottom: .zero,
                                    trailing: AppTheme.spacing.md
                                )
                            )
                            .listRowBackground(AppTheme.colors.appBackground)
                            .listRowSeparator(.hidden)

                        if bucket == .upcoming {
                            upcomingListContent
                        } else {
                            ForEach(filteredTasks(for: bucket)) { task in
                                taskListRow(task, in: bucket)
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
            onMoveToLater: bucket == .tomorrow ? { rescheduleTaskToLater(task) } : nil,
            onSchedule: bucket == .upcoming ? { presentSchedulePicker(for: task) } : nil
        )
    }

    private func taskListRow(_ task: TaskItem, in bucket: TaskBucket) -> some View {
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

    @ViewBuilder
    private var upcomingListContent: some View {
        let groups = upcomingSectionGroups()
        if groups.isEmpty {
            upcomingEmptyStateRow
        } else {
            ForEach(groups) { group in
                Section {
                    if isUpcomingSectionExpanded(group.section) {
                        ForEach(group.tasks) { task in
                            taskListRow(task, in: .upcoming)
                        }
                    }
                } header: {
                    upcomingSectionHeader(for: group.section, count: group.tasks.count)
                }
            }
        }
    }

    private var upcomingEmptyStateRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.xs) {
            Text("Nothing in Upcoming")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.colors.textPrimary)
            Text("Future tasks will appear here when you schedule them.")
                .font(AppTheme.fonts.body)
                .foregroundStyle(AppTheme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppTheme.spacing.md)
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
    }

    private func upcomingSectionHeader(for section: UpcomingSection, count: Int) -> some View {
        Button {
            toggleUpcomingSection(section)
        } label: {
            HStack(spacing: AppTheme.spacing.xs) {
                Image(systemName: isUpcomingSectionExpanded(section) ? "chevron.down" : "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.textSecondary)
                Text("\(section.title) (\(count))")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.textPrimary)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .textCase(nil)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.title)
        .accessibilityValue(isUpcomingSectionExpanded(section) ? "Expanded" : "Collapsed")
        .accessibilityHint("Shows or hides tasks in this section")
        .padding(.horizontal, AppTheme.spacing.md)
        .padding(.top, AppTheme.spacing.sm)
        .padding(.bottom, AppTheme.spacing.xs)
        .background(AppTheme.colors.appBackground)
    }

    private func isUpcomingSectionExpanded(_ section: UpcomingSection) -> Bool {
        upcomingSectionExpansionOverrides[section] ?? section.isExpandedByDefault
    }

    private func toggleUpcomingSection(_ section: UpcomingSection) {
        let updatedValue = !isUpcomingSectionExpanded(section)
        if updatedValue == section.isExpandedByDefault {
            upcomingSectionExpansionOverrides[section] = nil
        } else {
            upcomingSectionExpansionOverrides[section] = updatedValue
        }
    }

    private var upcomingVisibilitySignature: String {
        upcomingSectionGroups().map(\.section.rawValue).joined(separator: "|")
    }

    private func synchronizeUpcomingSectionVisibilityState() {
        let visibleSections = Set(upcomingSectionGroups().map(\.section))
        upcomingSectionExpansionOverrides = upcomingSectionExpansionOverrides.filter { visibleSections.contains($0.key) }
    }

    private func upcomingSectionGroups() -> [UpcomingSectionGroup] {
        let upcomingTasks = filteredTasks(for: .upcoming)
        let grouped = Dictionary(grouping: upcomingTasks, by: upcomingSection(for:))
        return UpcomingSection.allCases.compactMap { section in
            guard let sectionTasks = grouped[section], !sectionTasks.isEmpty else {
                return nil
            }
            return UpcomingSectionGroup(section: section, tasks: sortUpcomingTasks(sectionTasks, in: section))
        }
    }

    private func upcomingSection(for task: TaskItem) -> UpcomingSection {
        guard let dueDate = task.dueDate else {
            return .unscheduled
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) ?? currentWeekStart
        let weekAfterNextStart = calendar.date(byAdding: .weekOfYear, value: 2, to: currentWeekStart) ?? nextWeekStart
        let normalizedDueDate = calendar.startOfDay(for: dueDate)

        if normalizedDueDate < nextWeekStart {
            return .thisWeek
        }
        if normalizedDueDate < weekAfterNextStart {
            return .nextWeek
        }
        return .later
    }

    private func sortUpcomingTasks(_ items: [TaskItem], in section: UpcomingSection) -> [TaskItem] {
        switch section {
        case .unscheduled:
            return items.sorted { lhs, rhs in
                let lhsCreatedAt = lhs.createdAt ?? .distantPast
                let rhsCreatedAt = rhs.createdAt ?? .distantPast
                if lhsCreatedAt != rhsCreatedAt {
                    return lhsCreatedAt > rhsCreatedAt
                }
                return taskKey(for: lhs) < taskKey(for: rhs)
            }
        case .thisWeek, .nextWeek, .later:
            return items.sorted { lhs, rhs in
                let calendar = Calendar.current
                let lhsDue = calendar.startOfDay(for: lhs.dueDate ?? .distantFuture)
                let rhsDue = calendar.startOfDay(for: rhs.dueDate ?? .distantFuture)
                if lhsDue != rhsDue {
                    return lhsDue < rhsDue
                }
                let lhsCreatedAt = lhs.createdAt ?? .distantPast
                let rhsCreatedAt = rhs.createdAt ?? .distantPast
                if lhsCreatedAt != rhsCreatedAt {
                    return lhsCreatedAt > rhsCreatedAt
                }
                return taskKey(for: lhs) < taskKey(for: rhs)
            }
        }
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

    private func presentSchedulePicker(for task: TaskItem) {
        let calendar = Calendar.current
        schedulingTask = task
        schedulingDate = calendar.startOfDay(for: task.dueDate ?? Date())
        isScheduleSheetPresented = true
    }

    private func applyScheduledDate(_ date: Date) {
        guard let task = schedulingTask else { return }
        task.dueDate = Calendar.current.startOfDay(for: date)
        isScheduleSheetPresented = false
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
        _ = withAnimation(.easeInOut(duration: 0.14)) {
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

    private var scheduleSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
                DatePicker(
                    "Schedule",
                    selection: Binding(
                        get: { schedulingDate },
                        set: { newValue in
                            schedulingDate = newValue
                            applyScheduledDate(newValue)
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }
            .padding(AppTheme.spacing.md)
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
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
        let todayStart = calendar.startOfDay(for: Date())
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
                return !calendar.isDateInToday(dueDate)
                    && !calendar.isDateInTomorrow(dueDate)
                    && calendar.startOfDay(for: dueDate) >= todayStart
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
