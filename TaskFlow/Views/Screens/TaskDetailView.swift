import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var task: TaskItem
    
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var editedDescription = ""
    @State private var showingDeleteAlert = false
    @FocusState private var focusedField: FocusField?
    
    @State private var dueDateEnabled = false
    @State private var dueDateDraft = Date()
    @State private var reminderEnabled = false
    @State private var reminderDraft = Date()
    @State private var saveStatus: SaveStatus = .idle
    @State private var saveStatusTask: Task<Void, Never>?
    
    private enum FocusField {
        case title
        case description
    }

    private enum SaveStatus {
        case idle
        case saving
        case saved
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    saveIndicator
                    headerCard
                    scheduleCard
                    descriptionCard
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if isEditing {
                    Button("Cancel") {
                        cancelEditing()
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    Button("Done") {
                        saveEdits()
                    }
                    .fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Task", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                .accessibilityLabel("More actions")
            }
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: deleteTask)
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
        .onAppear(perform: syncScheduleState)
        .onDisappear {
            if isEditing {
                saveEdits()
            }
            saveStatusTask?.cancel()
            saveStatusTask = nil
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                if isEditing {
                    TextField("Task Title", text: $editedTitle)
                        .font(AppTheme.Typography.title)
                        .textFieldStyle(.plain)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .focused($focusedField, equals: .title)
                } else {
                    Text(task.safeTitle)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.text)
                        .lineLimit(2)
                }
                
                Spacer()
                
                TaskStatusBadge(task: task)
            }
            
            HStack(spacing: AppTheme.Spacing.sm) {
                Button(action: toggleCompletion) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: task.safeIsCompleted ? "checkmark.circle.fill" : "circle")
                        Text(task.safeIsCompleted ? "Completed" : "Mark Complete")
                    }
                    .font(AppTheme.Typography.body.weight(.semibold))
                    .foregroundStyle(task.safeIsCompleted ? AppTheme.Colors.success : AppTheme.Colors.primary)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .background(AppTheme.Colors.background)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                if let dueDate = task.dueDate {
                    Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(dueDateColor)
                } else {
                    Label("No due date", systemImage: "calendar")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Schedule Card
    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Schedule")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.text)
            
            Toggle("Due date", isOn: $dueDateEnabled)
                .onChange(of: dueDateEnabled) { _, isEnabled in
                    if isEnabled {
                        task.dueDate = dueDateDraft
                    } else {
                        task.dueDate = nil
                    }
                    refreshReminder()
                }
            
            if dueDateEnabled {
                DatePicker(
                    "Due",
                    selection: $dueDateDraft,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .onChange(of: dueDateDraft) { _, newValue in
                    task.dueDate = newValue
                    refreshReminder()
                }
            }
            
            Toggle("Reminder time", isOn: $reminderEnabled)
                .onChange(of: reminderEnabled) { _, isEnabled in
                    if isEnabled {
                        task.remindAt = reminderDraft
                    } else {
                        task.remindAt = nil
                    }
                    refreshReminder()
                }
            
            if reminderEnabled {
                DatePicker(
                    "Remind me",
                    selection: $reminderDraft,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .onChange(of: reminderDraft) { _, newValue in
                    task.remindAt = newValue
                    refreshReminder()
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Description Card
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Description")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.text)
            
            if isEditing {
                textEditorWithPlaceholder(
                    text: $editedDescription,
                    placeholder: "Add a short description, goals, or context.",
                    minHeight: 110
                )
                .focused($focusedField, equals: .description)
            } else {
                Button {
                    startEditing(focus: .description)
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "square.and.pencil")
                        Text(task.safeDescription.isEmpty ? "Add a note" : "Edit note")
                    }
                    .font(AppTheme.Typography.body.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                if !task.safeDescription.isEmpty {
                    Text(task.safeDescription)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .padding(.top, AppTheme.Spacing.sm)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var saveIndicator: some View {
        switch saveStatus {
        case .idle:
            EmptyView()
        case .saving:
            saveIndicatorLabel(text: "Saving…", icon: "hourglass")
        case .saved:
            saveIndicatorLabel(text: "Saved", icon: "checkmark.circle")
        }
    }

    private func saveIndicatorLabel(text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.Colors.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.Colors.background.opacity(0.9))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.Colors.secondaryText.opacity(0.2), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: 0.25), value: saveStatus)
    }
    
    // MARK: - Actions
    private func startEditing(focus: FocusField = .title) {
        editedTitle = task.safeTitle
        editedDescription = task.safeDescription
        isEditing = true
        focusedField = focus
    }
    
    private func cancelEditing() {
        editedTitle = task.safeTitle
        editedDescription = task.safeDescription
        isEditing = false
        focusedField = nil
    }
    
    private func saveEdits() {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespaces)
        if !trimmedTitle.isEmpty {
            task.taskTitle = trimmedTitle
            task.taskDescription = editedDescription.trimmingCharacters(in: .whitespaces)
        }
        isEditing = false
        focusedField = nil
        queueSaveStatus()
    }
    
    private func toggleCompletion() {
        withAnimation {
            task.isCompleted = !task.safeIsCompleted
            task.completionDate = task.safeIsCompleted ? Date() : nil
        }
        if task.safeIsCompleted {
            NotificationManager.shared.cancelReminder(for: task)
        } else {
            NotificationManager.shared.scheduleReminder(for: task)
        }
    }
    
    private func deleteTask() {
        NotificationManager.shared.cancelReminder(for: task)
        modelContext.delete(task)
        dismiss()
    }
    
    private var dueDateColor: Color {
        if task.safeIsCompleted {
            return AppTheme.Colors.success
        }
        if task.isOverdue {
            return AppTheme.Colors.danger
        }
        return AppTheme.Colors.secondaryText
    }
    
    private func textEditorWithPlaceholder(
        text: Binding<String>,
        placeholder: String,
        minHeight: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: text)
                .font(AppTheme.Typography.body)
                .frame(minHeight: minHeight)
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .scrollContentBackground(.hidden)
            
            if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .padding(.horizontal, AppTheme.Spacing.sm + 2)
                    .padding(.vertical, AppTheme.Spacing.sm + 6)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private func refreshReminder() {
        NotificationManager.shared.scheduleReminder(for: task)
    }
    
    private func syncScheduleState() {
        dueDateEnabled = task.dueDate != nil
        dueDateDraft = task.dueDate ?? Date()
        reminderEnabled = task.remindAt != nil
        reminderDraft = task.remindAt ?? defaultReminderDraft()
    }
    
    private func defaultReminderDraft() -> Date {
        if let dueDate = task.dueDate {
            let calendar = Calendar.current
            return calendar.date(
                bySettingHour: 9,
                minute: 0,
                second: 0,
                of: dueDate
            ) ?? dueDate
        }
        return Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    }

    private func queueSaveStatus() {
        saveStatusTask?.cancel()
        saveStatus = .saving
        let statusTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                saveStatus = .saved
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                saveStatus = .idle
            }
        }
        saveStatusTask = statusTask
    }
}

#Preview {
    let container = TaskPreviewData.container()
    let task = TaskPreviewData.makeDetailTask()
    container.mainContext.insert(task)
    
    return NavigationStack {
        TaskDetailView(task: task)
    }
    .modelContainer(container)
}
