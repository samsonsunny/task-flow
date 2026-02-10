import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var task: TaskItem
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var showingDeleteAlert = false
    @FocusState private var focusedField: FocusField?
    
    init(task: TaskItem) {
        self.task = task
        _editedTitle = State(initialValue: task.safeTitle)
    }
    
    @State private var dueDateEnabled = false
    @State private var dueDateDraft = Date()
    @State private var saveStatus: SaveStatus = .idle
    @State private var saveStatusTask: Task<Void, Never>?
    
    private enum FocusField {
        case title
    }

    private enum SaveStatus {
        case idle
        case saving
        case saved
    }

    var body: some View {
        ZStack {
            AppTheme.colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing.lg) {
                    saveIndicator
                    headerCard
                    scheduleCard
                }
                .padding(AppTheme.spacing.lg)
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

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
                        .foregroundStyle(AppTheme.colors.primary)
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
        CardView {
            VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
                HStack(alignment: .top, spacing: AppTheme.spacing.sm) {
                    if isEditing {
                        TextField("Task Title", text: $editedTitle)
                            .font(AppTheme.fonts.title)
                            .textFieldStyle(.plain)
                            .padding(.vertical, AppTheme.spacing.xs)
                            .focused($focusedField, equals: .title)
                    } else {
                        Text(task.safeTitle)
                            .font(AppTheme.fonts.title)
                            .foregroundStyle(AppTheme.colors.text)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: AppTheme.spacing.sm) {
                    Button(action: toggleCompletion) {
                        HStack(spacing: AppTheme.spacing.xs) {
                            Image(systemName: task.safeIsCompleted ? "checkmark.circle.fill" : "circle")
                            Text(task.safeIsCompleted ? "Completed" : "Complete")
                        }
                        .font(AppTheme.fonts.body.weight(.semibold))
                        .foregroundStyle(task.safeIsCompleted ? AppTheme.colors.success : AppTheme.colors.primary)
                        .padding(.vertical, AppTheme.spacing.sm)
                        .padding(.horizontal, AppTheme.spacing.md)
                        .background(AppTheme.colors.background)
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    if let dueDate = task.dueDate {
                        Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(AppTheme.fonts.caption)
                            .foregroundStyle(dueDateColor)
                    } else {
                        Label("No due date", systemImage: "calendar")
                            .font(AppTheme.fonts.caption)
                            .foregroundStyle(AppTheme.colors.secondaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Schedule Card
        private var scheduleCard: some View {
            CardView {
                VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
                    Text("Schedule")
                        .font(AppTheme.fonts.headline)
                        .foregroundStyle(AppTheme.colors.text)
                    
                    Toggle("Due date", isOn: $dueDateEnabled)
                        .onChange(of: dueDateEnabled) { _, isEnabled in
                            if isEnabled {
                                task.dueDate = dueDateDraft
                            } else {
                                task.dueDate = nil
                            }
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
                        }
                    }
                }
            }
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
            .font(AppTheme.fonts.caption)
            .foregroundStyle(AppTheme.colors.secondaryText)
            .padding(.horizontal, AppTheme.spacing.sm)
            .padding(.vertical, AppTheme.spacing.xs)
            .background(AppTheme.colors.background.opacity(0.9))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.colors.secondaryText.opacity(0.2), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: 0.25), value: saveStatus)
    }
    
    // MARK: - Actions
    private func startEditing(focus: FocusField = .title) {
        editedTitle = task.safeTitle
        isEditing = true
        focusedField = focus
    }
    
    private func cancelEditing() {
        editedTitle = task.safeTitle
        isEditing = false
        focusedField = nil
    }
    
    private func saveEdits() {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespaces)
        if !trimmedTitle.isEmpty {
            task.taskTitle = trimmedTitle
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
    }
    
    private func deleteTask() {
        modelContext.delete(task)
        dismiss()
    }
    
    private var dueDateColor: Color {
        if task.safeIsCompleted {
            return AppTheme.colors.success
        }
        if task.isOverdue {
            return AppTheme.colors.danger
        }
        return AppTheme.colors.secondaryText
    }
    
    private func syncScheduleState() {
        dueDateEnabled = task.dueDate != nil
        dueDateDraft = task.dueDate ?? Date()
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
