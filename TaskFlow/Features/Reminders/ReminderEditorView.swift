import SwiftUI
import SwiftData

struct ReminderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderList.name) private var reminderLists: [ReminderList]
    @Query(sort: \ReminderTag.label) private var reminderTags: [ReminderTag]

    private let task: TaskItem?
    private let initialDate: Date?
    private let initialListID: ReminderList.ID?
    private let initialTitle: String

    @State private var viewModel: ReminderEditorViewModel?
    @State private var expandedPicker: ExpandedPicker?
    @State private var pressedRow: ExpandedPicker?
    @State private var newSubtaskTitle = ""
    @State private var editingSubtask: TaskItem?
    @FocusState private var isTitleFocused: Bool

    init(task: TaskItem? = nil, initialDate: Date? = nil, initialListID: ReminderList.ID? = nil, initialTitle: String = "") {
        self.task = task
        self.initialDate = initialDate
        self.initialListID = initialListID
        self.initialTitle = initialTitle
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
                let vm = ReminderEditorViewModel(
                    modelContext: modelContext,
                    task: task,
                    reminderLists: reminderLists,
                    reminderTags: reminderTags,
                    initialDate: initialDate,
                    initialListID: initialListID,
                    initialTitle: initialTitle
                )
                viewModel = vm
                isTitleFocused = true
            }
            .onChange(of: reminderLists) { _, newValue in
                viewModel?.update(reminderLists: newValue, reminderTags: reminderTags)
            }
            .onChange(of: reminderTags) { _, newValue in
                viewModel?.update(reminderLists: reminderLists, reminderTags: newValue)
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
                    .disabled(viewModel?.draft.normalizedTitle.isEmpty ?? true)
                    .accessibilityIdentifier("reminder-editor-save")
                }
            }
            .sheet(item: $editingSubtask) { subtask in
                ReminderEditorView(task: subtask)
            }
            .alert("Discard Changes?", isPresented: discardConfirmationBinding) {
                Button("Keep Editing", role: .cancel) {}
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Your draft has unsaved changes.")
            }
        }
    }

    private var discardConfirmationBinding: Binding<Bool> {
        .init(
            get: { viewModel?.isDiscardConfirmationPresented ?? false },
            set: { viewModel?.isDiscardConfirmationPresented = $0 }
        )
    }

    private var draftBinding: Binding<ReminderDraft> {
        .init(
            get: { viewModel?.draft ?? .empty },
            set: { viewModel?.draft = $0 }
        )
    }

    private var contentSection: some View {
        Section {
            TextField("Title", text: draftBinding.title, axis: .vertical)
                .lineLimit(1...4)
                .font(.title3)
                .focused($isTitleFocused)
                .accessibilityIdentifier("reminder-editor-title")

            TextField("Notes", text: draftBinding.notes, axis: .vertical)
                .lineLimit(1...4)
                .accessibilityIdentifier("reminder-editor-notes")

            HStack {
                TextField("URL", text: draftBinding.urlString)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("reminder-editor-url")

                if !(viewModel?.draft.normalizedURL.isEmpty ?? true) {
                    Button {
                        viewModel?.draft.urlString = ""
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
                    selection: dateBinding,
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
                    selection: timeBinding,
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

    private var dateBinding: Binding<Date> {
        .init(
            get: { viewModel?.draft.dueDate ?? initialDate ?? Date() },
            set: { viewModel?.draft.dueDate = $0 }
        )
    }

    private var timeBinding: Binding<Date> {
        .init(
            get: { viewModel?.draft.dueDate ?? initialDate ?? Date() },
            set: { viewModel?.draft.dueDate = $0 }
        )
    }

    private var dateRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Date")
                if let date = viewModel?.draft.dueDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(AppTheme.colors.textSecondary)
                }
            }

            Spacer()

            Toggle("Date", isOn: .init(
                get: { viewModel?.draft.dueDate != nil },
                set: { isEnabled in
                    if isEnabled {
                        viewModel?.draft.dueDate = viewModel?.draft.dueDate ?? initialDate ?? Date()
                        expandedPicker = .date
                    } else {
                        viewModel?.draft.dueDate = nil
                        viewModel?.draft.hasTime = false
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
                    guard viewModel?.draft.dueDate != nil else { return }
                    pressedRow = .date
                }
                .onEnded { _ in
                    pressedRow = nil
                    guard viewModel?.draft.dueDate != nil else { return }
                    expandedPicker = expandedPicker == .date ? nil : .date
                }
        )
    }

    private var timeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Time")
                if viewModel?.draft.hasTime == true, let date = viewModel?.draft.dueDate {
                    Text(date, style: .time)
                        .font(.caption)
                        .foregroundStyle(AppTheme.colors.textSecondary)
                }
            }

            Spacer()

            Toggle("Time", isOn: .init(
                get: { viewModel?.draft.hasTime ?? false },
                set: { isEnabled in
                    if isEnabled {
                        viewModel?.draft.hasTime = true
                        let calendar = Calendar.current
                        let baseDate: Date
                        if let date = viewModel?.draft.dueDate {
                            baseDate = date
                        } else {
                            baseDate = initialDate ?? Date()
                        }
                        var dayComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
                        let rounded = nearestRoundedHour()
                        let timeComponents = calendar.dateComponents([.hour, .minute], from: rounded)
                        dayComponents.hour = timeComponents.hour
                        dayComponents.minute = timeComponents.minute
                        viewModel?.draft.dueDate = calendar.date(from: dayComponents) ?? rounded
                        expandedPicker = .time
                    } else {
                        viewModel?.draft.hasTime = false
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
                    guard viewModel?.draft.hasTime == true else { return }
                    pressedRow = .time
                }
                .onEnded { _ in
                    pressedRow = nil
                    guard viewModel?.draft.hasTime == true else { return }
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
        viewModel?.handleClose()
        if viewModel?.isDirty == false {
            dismiss()
        }
    }

    private func saveReminder() {
        guard viewModel?.draft.hasMeaningfulContent == true else { return }
        viewModel?.save()
        dismiss()
    }

    @ViewBuilder
    private func subtaskSection(for parent: TaskItem) -> some View {
        Section("Subtasks") {
            ForEach(parent.subtasks) { subtask in
                TaskRowView(
                    task: subtask,
                    isCompletedVisualState: subtask.isCompleted == true,
                    onToggleCompletion: { viewModel?.toggleSubtaskCompletion(subtask) },
                    onTap: { editingSubtask = subtask },
                    showsDueDate: false,
                    showsListName: false
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let subtask = parent.subtasks[index]
                    viewModel?.deleteSubtask(subtask)
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
        viewModel?.addSubtask(title: text, to: parent)
        newSubtaskTitle = ""
    }
}

#Preview("New Reminder") {
    let container = TaskPreviewData.container()
    TaskPreviewData.ensureDefaultListExists(in: container.mainContext)

    return ReminderEditorView()
        .modelContainer(container)
}
