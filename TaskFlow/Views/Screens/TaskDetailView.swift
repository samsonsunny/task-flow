import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var task: TaskItem
    
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var editedDescription = ""
    @State private var newSubtaskTitle = ""
    @State private var newLogNote = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    headerCard
                    descriptionCard
                    subtasksCard
                    dailyLogCard
                    deleteButton
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing { saveEdits() } else { startEditing() }
                }
                .fontWeight(.semibold)
            }
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: deleteTask)
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if isEditing {
                TextField("Task Title", text: $editedTitle)
                    .font(AppTheme.Typography.title)
                    .textFieldStyle(.plain)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(task.safeTitle)
                    .font(AppTheme.Typography.title)
                    .foregroundStyle(AppTheme.Colors.text)
            }
            
            HStack {
                TaskStatusBadge(task: task)
                Spacer()
                
                Button(action: toggleCompletion) {
                    HStack {
                        Image(systemName: task.safeIsCompleted ? "checkmark.circle.fill" : "circle")
                        Text(task.safeIsCompleted ? "Completed" : "Mark Complete")
                    }
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(task.safeIsCompleted ? AppTheme.Colors.success : AppTheme.Colors.primary)
                }
            }
            
            Divider()
            
            // Metadata
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Label("Due: \(task.safeDueDate.formatted(date: .long, time: .omitted))", systemImage: "calendar")
                Label("Created: \(task.safeCreatedAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock")
                
                if let completionDate = task.completionDate {
                    Label("Completed: \(completionDate.formatted(date: .abbreviated, time: .shortened))", systemImage: "checkmark.circle")
                        .foregroundStyle(AppTheme.Colors.success)
                }
            }
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Description Card
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Description")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.text)
            
            if isEditing {
                TextEditor(text: $editedDescription)
                    .font(AppTheme.Typography.body)
                    .frame(minHeight: 100)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .scrollContentBackground(.hidden)
            } else {
                Text(task.safeDescription.isEmpty ? "No description" : task.safeDescription)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(task.safeDescription.isEmpty ? AppTheme.Colors.secondaryText : AppTheme.Colors.text)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Subtasks Card
    private var subtasksCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Subtasks")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.text)
                
                Spacer()
                
                if !task.safeSubtasks.isEmpty {
                    Text("\(task.completedSubtasksCount)/\(task.safeSubtasks.count)")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            }
            
            if task.safeSubtasks.isEmpty {
                Text("No subtasks")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            } else {
                ForEach(task.safeSubtasks.sorted(by: { $0.safeCreatedAt < $1.safeCreatedAt })) { subtask in
                    SubtaskRow(subtask: subtask, onDelete: {
                        deleteSubtask(subtask)
                    })
                }
            }
            
            // Add subtask input
            HStack {
                TextField("Add subtask", text: $newSubtaskTitle)
                    .font(AppTheme.Typography.body)
                    .textFieldStyle(.plain)
                    .onSubmit(addSubtask)
                
                Button(action: addSubtask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Daily Log Card
    private var dailyLogCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Daily Log")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.text)
            
            if task.safeDailyLog.isEmpty {
                Text("No log entries")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            } else {
                ForEach(task.safeDailyLog.sorted(by: { $0.safeTimestamp > $1.safeTimestamp })) { entry in
                    DailyLogCard(entry: entry, onDelete: {
                        deleteLogEntry(entry)
                    })
                }
            }
            
            // Add log entry
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                TextEditor(text: $newLogNote)
                    .font(AppTheme.Typography.body)
                    .frame(minHeight: 80)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .scrollContentBackground(.hidden)
                
                Button(action: addLogEntry) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Log Entry")
                    }
                    .font(AppTheme.Typography.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(newLogNote.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Delete Button
    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Task")
            }
            .font(AppTheme.Typography.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.danger)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Actions
    private func startEditing() {
        editedTitle = task.safeTitle
        editedDescription = task.safeDescription
        isEditing = true
    }
    
    private func saveEdits() {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespaces)
        if !trimmedTitle.isEmpty {
            task.taskTitle = trimmedTitle
            task.taskDescription = editedDescription.trimmingCharacters(in: .whitespaces)
        }
        isEditing = false
    }
    
    private func toggleCompletion() {
        withAnimation {
            task.isCompleted = !task.safeIsCompleted
            task.completionDate = task.safeIsCompleted ? Date() : nil
        }
    }
    
    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let subtask = Subtask(title: trimmed)
        
        if task.subtasks == nil {
            task.subtasks = []
        }
        task.subtasks?.append(subtask)
        
        newSubtaskTitle = ""
    }
    
    private func deleteSubtask(_ subtask: Subtask) {
        withAnimation {
            modelContext.delete(subtask)
        }
    }
    
    private func addLogEntry() {
        let trimmed = newLogNote.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let entry = DailyLogEntry(note: trimmed)
        
        if task.dailyLog == nil {
            task.dailyLog = []
        }
        task.dailyLog?.append(entry)
        
        newLogNote = ""
    }
    
    private func deleteLogEntry(_ entry: DailyLogEntry) {
        withAnimation {
            modelContext.delete(entry)
        }
    }
    
    private func deleteTask() {
        modelContext.delete(task)
        dismiss()
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
