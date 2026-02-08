//
//  TaskListView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI
import SwiftData

enum AppScreen: Hashable {
    case overdue
    case completed
}

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    
    @FocusState private var addTaskFocused: Bool
    @AppStorage("dailyReviewEnabled") private var dailyReviewEnabled = true
    @AppStorage("taskflow.notifications.enabled") private var notificationsEnabled = false
    @AppStorage("taskflow.notifications.denied") private var notificationsDenied = false
    @State private var isRequestingReminderPermission = false
    @State private var reminderPromptHighlighted = false

    let shouldFocusOnAppear: Bool

    init(shouldFocusOnAppear: Bool = false) {
        self.shouldFocusOnAppear = shouldFocusOnAppear
    }
    
    private var incompleteTasks: [TaskItem] {
        tasks.filter { !$0.safeIsCompleted }
    }
    
    private var completedTasksCount: Int {
        tasks.filter { $0.safeIsCompleted }.count
    }
    
    private var hasCompletedTasks: Bool {
        completedTasksCount > 0
    }
    
    private var hasAnyTasks: Bool {
        !tasks.isEmpty
    }

    private var shouldShowReminderPrompt: Bool {
        !notificationsEnabled && !notificationsDenied
    }

    private enum TaskSection: String, CaseIterable, Identifiable {
        case today = "Today"
        case upcoming = "Upcoming"
        case later = "Later"
        case noDueDate = "Someday"

        var id: String { self.rawValue }
    }
    
    private var overdueTasks: [TaskItem] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        return incompleteTasks.filter {
            guard let referenceDate = $0.reminderReferenceDate else { return false }
            return referenceDate < todayStart
        }
    }
    
    private var sectionedTasks: [(TaskSection, [TaskItem])] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let upcomingLimit = calendar.date(byAdding: .day, value: 7, to: todayStart) ?? todayStart
        
        var buckets: [TaskSection: [TaskItem]] = [
            .today: [],
            .upcoming: [],
            .later: [],
            .noDueDate: []
        ]
        
        for task in incompleteTasks {
            guard let due = task.reminderReferenceDate else {
                buckets[.noDueDate, default: []].append(task)
                continue
            }
            if due < todayStart {
                // Overdue handled separately
                continue
            } else if calendar.isDateInToday(due) {
                buckets[.today, default: []].append(task)
            } else if due <= upcomingLimit {
                buckets[.upcoming, default: []].append(task)
            } else {
                buckets[.later, default: []].append(task)
            }
        }
        
        return ([TaskSection.today, TaskSection.upcoming, TaskSection.later, TaskSection.noDueDate]).compactMap { section in
            guard let items = buckets[section], !items.isEmpty else { return nil }
            return (section, items)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacing.md) {
                        if shouldShowReminderPrompt {
                            reminderPrompt
                        }
                        if incompleteTasks.isEmpty {
                            EmptyStateView(type: hasAnyTasks ? .allDone : .noTasks)
                        } else {
                            if !overdueTasks.isEmpty {
                                overdueTasksLink
                            }
                            
                            ForEach(sectionedTasks, id: \.0) { section, items in
                                Text(section.rawValue)
                                    .font(AppTheme.fonts.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.colors.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, AppTheme.spacing.sm)
                                
                                ForEach(items) { task in
                                    taskRow(task)
                                }
                            }
                            
                            if hasCompletedTasks {
                                completedTasksLink
                            }
                        }
        }
        .padding(.horizontal, AppTheme.spacing.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radius.large, style: .continuous)
                .stroke(reminderPromptHighlighted ? AppTheme.colors.primary : .clear, lineWidth: 1.5)
        )
                    .padding(.top, AppTheme.spacing.md)
                    .padding(.bottom, AppTheme.spacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        addTaskFocused = false
                    }
                )
                .animation(.easeInOut, value: incompleteTasks.count)
                .animation(.easeInOut, value: completedTasksCount)
            }
            .navigationTitle("Tasks")
            .onAppear {
                if shouldFocusOnAppear {
                    DispatchQueue.main.async {
                        addTaskFocused = true
                    }
                }
            }
            .navigationDestination(for: TaskItem.self) { task in
                TaskDetailView(task: task)
            }
            .navigationDestination(for: AppScreen.self) { screen in
                switch screen {
                case .overdue:
                    OverdueTasksView()
                case .completed:
                    CompletedTasksView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                InlineAddTaskRow(isFocused: $addTaskFocused, onCreate: createInlineTask)
            }
        }
    }
    


    private var overdueTasksLink: some View {
        NavigationLink(value: AppScreen.overdue) {
            HStack {
                Text("Overdue")
                    .font(AppTheme.fonts.body.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.text)
                Spacer()
                Text("\(overdueTasks.count)")
                    .font(AppTheme.fonts.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.secondaryText)
                    .padding(.horizontal, AppTheme.spacing.xs)
                    .padding(.vertical, AppTheme.spacing.xxs)
                    .background(AppTheme.colors.background)
                    .clipShape(Capsule())
                Image(systemName: "chevron.right")
                    .font(AppTheme.fonts.caption2)
                    .foregroundStyle(AppTheme.colors.secondaryText)
            }
            .padding(.horizontal, AppTheme.spacing.md)
            .padding(.vertical, AppTheme.spacing.sm)
            .background(AppTheme.colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.medium))
        }
        .buttonStyle(.plain)
    }
    
    private var completedTasksLink: some View {
        NavigationLink(value: AppScreen.completed) {
            HStack {
                Text("Completed")
                    .font(AppTheme.fonts.body.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.text)
                Spacer()
                Text("\(completedTasksCount)")
                    .font(AppTheme.fonts.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.secondaryText)
                    .padding(.horizontal, AppTheme.spacing.xs)
                    .padding(.vertical, AppTheme.spacing.xxs)
                    .background(AppTheme.colors.background)
                    .clipShape(Capsule())
                Image(systemName: "chevron.right")
                    .font(AppTheme.fonts.caption2)
                    .foregroundStyle(AppTheme.colors.secondaryText)
            }
            .padding(.horizontal, AppTheme.spacing.md)
            .padding(.vertical, AppTheme.spacing.sm)
            .background(AppTheme.colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.medium))
        }
        .buttonStyle(.plain)
    }

    private var reminderPrompt: some View {
        HStack(spacing: AppTheme.spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.spacing.xxs) {
                Text("Enable gentle reminders")
                    .font(AppTheme.fonts.body.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.text)
                Text("TaskFlow can nudge you when things are due.")
                    .font(AppTheme.fonts.caption)
                    .foregroundStyle(AppTheme.colors.secondaryText)
            }
            Spacer()
            Button {
                requestReminderPermission()
            } label: {
                Text("Enable")
                    .frame(minWidth: 90)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequestingReminderPermission)
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.large, style: .continuous))
    }
    
    private func taskRow(_ task: TaskItem) -> some View {
        NavigationLink(value: task) {
            TaskRowView(task: task)
        }
        .buttonStyle(.plain)
    }
    
    private func requestReminderPermission() {
        guard !isRequestingReminderPermission else { return }
        isRequestingReminderPermission = true
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            await MainActor.run {
                notificationsEnabled = granted
                notificationsDenied = !granted
                if granted && dailyReviewEnabled {
                    NotificationManager.shared.scheduleDailyReview()
                }
                isRequestingReminderPermission = false
            }
        }
    }

    private func pulseReminderPrompt() {
        reminderPromptHighlighted = true
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            await MainActor.run {
                reminderPromptHighlighted = false
            }
        }
    }

    private func createInlineTask(title: String, dueDate: Date?) {
        let task = TaskItem(
            taskTitle: title,
            dueDate: dueDate
        )
        modelContext.insert(task)
        NotificationManager.shared.scheduleReminder(for: task)
        if !notificationsEnabled && !notificationsDenied {
            pulseReminderPrompt()
        }
    }
    
}

private struct CompletedTasksView: View {
    @Query(filter: #Predicate<TaskItem> { $0.isCompleted == true }, sort: \TaskItem.dueDate) private var completedTasks: [TaskItem]
    
    var body: some View {
        ZStack {
            AppTheme.colors.background
                .ignoresSafeArea()
            
            if completedTasks.isEmpty {
            EmptyStateView(type: .noCompleted)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacing.sm) {
                        ForEach(completedTasks) { task in
                            NavigationLink(value: task) {
                                TaskRowView(task: task, statusStyle: .completedMetadata)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing.md)
                    .padding(.top, AppTheme.spacing.sm)
                    .padding(.bottom, AppTheme.spacing.lg)
                }
            }
        }
        .navigationTitle("Completed")
    }
}

private struct OverdueTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<TaskItem> { $0.isCompleted == false }, sort: \TaskItem.dueDate) private var activeTasks: [TaskItem]
    
    private var overdueTasks: [TaskItem] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        return activeTasks.filter {
            guard let referenceDate = $0.reminderReferenceDate else { return false }
            return referenceDate < todayStart
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.colors.background
                .ignoresSafeArea()
            
            if overdueTasks.isEmpty {
            EmptyStateView(type: .noOverdue)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacing.md) {
                        ForEach(overdueTasks) { task in
                            NavigationLink(value: task) {
                                TaskRowView(task: task)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    reschedule(task, daysFromToday: 0)
                                } label: {
                                    Label("Move to Today", systemImage: "calendar")
                                }
                                .tint(AppTheme.colors.primary)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    markDone(task)
                                } label: {
                                    Label("Done", systemImage: "checkmark")
                                }
                                .tint(AppTheme.colors.success)
                            }
                            .contextMenu {
                                Button("Mark Done") { markDone(task) }
                                Button("Move to Today") { reschedule(task, daysFromToday: 0) }
                                Button("Move to Tomorrow") { reschedule(task, daysFromToday: 1) }
                                Button("Move to Next Week") { reschedule(task, daysFromToday: 7) }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing.md)
                    .padding(.top, AppTheme.spacing.sm)
                    .padding(.bottom, AppTheme.spacing.lg)
                }
            }
        }
        .navigationTitle("Overdue")
    }
    
    private func reschedule(_ task: TaskItem, daysFromToday: Int) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let newDate = calendar.date(byAdding: .day, value: daysFromToday, to: todayStart) ?? todayStart
        task.dueDate = newDate
        modelContext.insert(task)
        NotificationManager.shared.scheduleReminder(for: task)
    }

    private func markDone(_ task: TaskItem) {
        task.isCompleted = true
        task.completionDate = Date()
        modelContext.insert(task)
        NotificationManager.shared.cancelReminder(for: task)
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
