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
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
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
        }

        dismiss()
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
