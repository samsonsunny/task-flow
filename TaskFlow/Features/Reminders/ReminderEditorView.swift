import SwiftUI
import SwiftData

struct ReminderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderList.name) private var reminderLists: [ReminderList]
    @Query(sort: \ReminderTag.label) private var reminderTags: [ReminderTag]

    private let task: TaskItem?
    private let initialDraft: ReminderDraft
    private let initialDate: Date?
    private let initialListID: ReminderList.ID?

    @State private var draft: ReminderDraft
    @State private var isDiscardConfirmationPresented = false
    @State private var expandedPicker: ExpandedPicker?
    @State private var pressedRow: ExpandedPicker?
    @State private var newSubtaskTitle = ""
    @State private var editingSubtask: TaskItem?
    @FocusState private var isTitleFocused: Bool

    @MainActor
    init(task: TaskItem? = nil, initialDate: Date? = nil, initialListID: ReminderList.ID? = nil, initialTitle: String = "") {
        self.task = task
        self.initialDate = initialDate
        self.initialListID = initialListID
        let initialDraft: ReminderDraft
        if let task = task {
            initialDraft = ReminderDraft(task: task)
        } else {
            var draft = ReminderDraft.empty
            draft.dueDate = initialDate
            draft.title = initialTitle
            initialDraft = draft
        }
        self.initialDraft = initialDraft
        _draft = State(initialValue: initialDraft)
    }

    var body: some View {
        NavigationStack {
            Form {
                contentSection
                scheduleSection
                if let parent = task {
                    subtaskSection(for: parent)
                }
            }
            .navigationTitle(task == nil ? "New Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isTitleFocused = true
                if let initialListID, draft.listName.isEmpty {
                    if let list = try? modelContext.model(for: initialListID) as? ReminderList {
                        draft.listName = list.name
                    }
                }
            }
            .onChange(of: expandedPicker) { _, _ in isTitleFocused = false }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        handleClose()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityIdentifier("reminder-editor-close")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .disabled(draft.normalizedTitle.isEmpty)
                    .accessibilityIdentifier("reminder-editor-save")
                }
            }
            .sheet(item: $editingSubtask) { subtask in
                ReminderEditorView(task: subtask)
            }
            .alert("Discard Changes?", isPresented: $isDiscardConfirmationPresented) {
                Button("Keep Editing", role: .cancel) {}
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Your draft has unsaved changes.")
            }
        }
    }

    private var contentSection: some View {
        Section {
            TextField("Title", text: $draft.title, axis: .vertical)
                .lineLimit(1...4)
                .font(.title3)
                .focused($isTitleFocused)
                .accessibilityIdentifier("reminder-editor-title")

            TextField("Notes", text: $draft.notes, axis: .vertical)
                .lineLimit(1...4)
                .accessibilityIdentifier("reminder-editor-notes")

            HStack {
                TextField("URL", text: $draft.urlString)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("reminder-editor-url")

                if !draft.normalizedURL.isEmpty {
                    Button {
                        draft.urlString = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("reminder-editor-url-clear")
                }
            }
        }
    }

    private var scheduleSection: some View {
        Section("Date & Time") {
            dateRow
            if expandedPicker == .date {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { draft.dueDate ?? Date() },
                        set: { newDate in
                            draft.dueDate = newDate
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .accessibilityIdentifier("reminder-editor-date-picker")
                .transition(.push(from: .top))
            }

            timeRow
            if expandedPicker == .time {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { draft.dueDate ?? Date() },
                        set: { newDate in
                            draft.dueDate = newDate
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 150)
                .clipped()
                .accessibilityIdentifier("reminder-editor-time-picker")
                .transition(.push(from: .top))
            }
        }
        .animation(.smooth(duration: 0.3), value: expandedPicker)
    }

    private var dateRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Date")
                if let date = draft.dueDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(AppTheme.colors.textSecondary)
                }
            }

            Spacer()

            Toggle("Date", isOn: Binding(
                get: { draft.dueDate != nil },
                set: { isEnabled in
                    if isEnabled {
                        draft.dueDate = draft.dueDate ?? initialDate ?? Date()
                        expandedPicker = .date
                    } else {
                        draft.dueDate = nil
                        draft.hasTime = false
                        expandedPicker = nil
                    }
                }
            ))
            .labelsHidden()
            .accessibilityIdentifier("reminder-editor-has-date")
        }
        .contentShape(Rectangle())
        .listRowBackground(
            pressedRow == .date
                ? AppTheme.colors.textSecondary.opacity(0.15)
                : Color(.secondarySystemGroupedBackground)
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard draft.dueDate != nil else { return }
                    pressedRow = .date
                }
                .onEnded { _ in
                    pressedRow = nil
                    guard draft.dueDate != nil else { return }
                    expandedPicker = expandedPicker == .date ? nil : .date
                }
        )
    }

    private var timeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Time")
                if draft.hasTime, let date = draft.dueDate {
                    Text(date, style: .time)
                        .font(.caption)
                        .foregroundStyle(AppTheme.colors.textSecondary)
                }
            }

            Spacer()

            Toggle("Time", isOn: Binding(
                get: { draft.hasTime },
                set: { isEnabled in
                    if isEnabled {
                        draft.hasTime = true
                        let calendar = Calendar.current
                        let baseDate: Date
                        if let date = draft.dueDate {
                            baseDate = date
                        } else {
                            baseDate = initialDate ?? Date()
                        }
                        var dayComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
                        let rounded = nearestRoundedHour()
                        let timeComponents = calendar.dateComponents([.hour, .minute], from: rounded)
                        dayComponents.hour = timeComponents.hour
                        dayComponents.minute = timeComponents.minute
                        draft.dueDate = calendar.date(from: dayComponents) ?? rounded
                        expandedPicker = .time
                    } else {
                        draft.hasTime = false
                        expandedPicker = nil
                    }
                }
            ))
            .labelsHidden()
            .accessibilityIdentifier("reminder-editor-has-time")
        }
        .contentShape(Rectangle())
        .listRowBackground(
            pressedRow == .time
                ? AppTheme.colors.textSecondary.opacity(0.15)
                : Color(.secondarySystemGroupedBackground)
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard draft.hasTime else { return }
                    pressedRow = .time
                }
                .onEnded { _ in
                    pressedRow = nil
                    guard draft.hasTime else { return }
                    expandedPicker = expandedPicker == .time ? nil : .time
                }
        )
    }

    private func nearestRoundedHour() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let totalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let rounded = ((totalMinutes + 29) / 30) * 30
        let clamped = rounded % (24 * 60)
        return calendar.date(bySettingHour: clamped / 60, minute: clamped % 60, second: 0, of: now) ?? now
    }

    private enum ExpandedPicker {
        case date
        case time
    }

    private func handleClose() {
        if isDirty {
            isDiscardConfirmationPresented = true
        } else {
            dismiss()
        }
    }

    private func saveReminder() {
        guard draft.hasMeaningfulContent else { return }

        let target = task ?? TaskItem()
        ReminderDraftMapper.apply(
            draft,
            to: target,
            availableLists: reminderLists,
            availableTags: reminderTags,
            in: modelContext
        )

        if task == nil {
            if target.createdAt == nil {
                target.createdAt = Date()
            }
            if target.taskId == nil {
                target.taskId = UUID().uuidString
            }
            modelContext.insert(target)
            assignInitialSortOrder(target)
        }

        let notif = NotificationService.shared
        if draft.hasTime {
            Task {
                guard await notif.requestAuthorizationIfNeeded() else { return }
                notif.schedule(for: target)
            }
        } else {
            if let taskId = target.taskId {
                notif.cancel(taskId: taskId)
            }
        }

        dismiss()
    }

    private func assignInitialSortOrder(_ task: TaskItem) {
        guard let list = task.reminderList else { return }
        guard let existing = try? modelContext.fetch(FetchDescriptor<TaskItem>()) else { return }
        let lastOrder = existing
            .filter { $0.reminderList?.persistentModelID == list.persistentModelID && $0.persistentModelID != task.persistentModelID }
            .compactMap { $0.sortOrder }
            .sorted()
            .last
        task.sortOrder = midpoint(between: lastOrder, and: nil)
    }

    @ViewBuilder
    private func subtaskSection(for parent: TaskItem) -> some View {
        Section("Subtasks") {
            ForEach(parent.subtasks) { subtask in
                TaskRowView(
                    task: subtask,
                    isCompletedVisualState: subtask.isCompleted == true,
                    onToggleCompletion: { toggleSubtaskCompletion(subtask) },
                    onTap: { editingSubtask = subtask },
                    showsDueDate: false,
                    showsListName: false
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let subtask = parent.subtasks[index]
                    modelContext.delete(subtask)
                }
            }

            HStack {
                TextField("Add Subtask", text: $newSubtaskTitle)
                    .onSubmit {
                        addSubtask(to: parent)
                    }
                Button {
                    addSubtask(to: parent)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppTheme.colors.primaryAction)
                }
            }
        }
    }

    private func addSubtask(to parent: TaskItem) {
        let text = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let subtask = TaskItem(
            taskTitle: text,
            dueDate: nil
        )
        subtask.createdAt = Date()
        subtask.reminderList = parent.reminderList
        subtask.parentTask = parent
        let subbies = parent.subtasks.filter { $0.persistentModelID != subtask.persistentModelID }
            .sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
        let lastOrder = subbies.last?.sortOrder
        subtask.sortOrder = midpoint(between: lastOrder, and: nil)
        modelContext.insert(subtask)
        newSubtaskTitle = ""
    }

    private func toggleSubtaskCompletion(_ subtask: TaskItem) {
        let next = !(subtask.isCompleted ?? false)
        subtask.isCompleted = next
        subtask.completionDate = next ? Date() : nil
        if next, let taskId = subtask.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
    }

    private var isDirty: Bool {
        draft != initialDraft
    }
}

#Preview("New Reminder") {
    let container = TaskPreviewData.container()
    TaskPreviewData.ensureDefaultListExists(in: container.mainContext)

    return ReminderEditorView()
        .modelContainer(container)
}
