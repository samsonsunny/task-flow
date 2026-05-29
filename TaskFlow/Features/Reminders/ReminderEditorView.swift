import SwiftUI
import SwiftData

struct ReminderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderList.name) private var reminderLists: [ReminderList]
    @Query(sort: \ReminderTag.label) private var reminderTags: [ReminderTag]

    private let task: TaskItem?
    private let initialDraft: ReminderDraft

    @State private var draft: ReminderDraft
    @State private var isDiscardConfirmationPresented = false
    @FocusState private var isTitleFocused: Bool

    @MainActor
    init(task: TaskItem? = nil, initialDate: Date? = nil) {
        self.task = task
        let initialDraft: ReminderDraft
        if let task = task {
            initialDraft = ReminderDraft(task: task)
        } else {
            var draft = ReminderDraft.empty
            draft.dueDate = initialDate
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
            .onAppear { isTitleFocused = true }
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
                .lineLimit(2...4)
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
        Section {
            HStack {
                Toggle(
                    "Due Date",
                    isOn: Binding(
                        get: { draft.dueDate != nil },
                        set: { isEnabled in
                            draft.dueDate = isEnabled ? (draft.dueDate ?? Date()) : nil
                        }
                    )
                )
                .accessibilityIdentifier("reminder-editor-has-date")

                if draft.dueDate != nil {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { draft.dueDate ?? Date() },
                            set: { draft.dueDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .accessibilityIdentifier("reminder-editor-date")
                }
            }
        }
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
