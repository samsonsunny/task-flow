import Foundation
import SwiftData

struct ReminderDraft: Equatable {
    var title: String
    var notes: String
    var urlString: String
    var listName: String
    var tagLabels: [String]
    var priority: ReminderPriority
    var assignedContactName: String
    var imageAttachmentReference: String
    var dueDate: Date?
    var hasTime: Bool

    static let empty = ReminderDraft(
        title: "",
        notes: "",
        urlString: "",
        listName: "",
        tagLabels: [],
        priority: .none,
        assignedContactName: "",
        imageAttachmentReference: "",
        dueDate: nil,
        hasTime: false
    )

    init(
        title: String,
        notes: String,
        urlString: String,
        listName: String,
        tagLabels: [String],
        priority: ReminderPriority,
        assignedContactName: String,
        imageAttachmentReference: String,
        dueDate: Date?,
        hasTime: Bool = false
    ) {
        self.title = title
        self.notes = notes
        self.urlString = urlString
        self.listName = listName
        self.tagLabels = tagLabels
        self.priority = priority
        self.assignedContactName = assignedContactName
        self.imageAttachmentReference = imageAttachmentReference
        self.dueDate = dueDate
        self.hasTime = hasTime
    }

    @MainActor
    init(task: TaskItem) {
        self.title = task.taskTitle ?? ""
        self.notes = task.notes
        self.urlString = task.reminderURL
        self.listName = task.reminderList?.name ?? ""
        self.tagLabels = task.tagLabels
        self.priority = task.priority
        self.assignedContactName = task.assignedContactName ?? ""
        self.imageAttachmentReference = task.imageAttachmentReference ?? ""
        self.dueDate = task.dueDate
        if let date = task.dueDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: date)
            self.hasTime = (components.hour != 0 || components.minute != 0)
        } else {
            self.hasTime = false
        }
    }

    var hasMeaningfulContent: Bool {
        normalizedTitle.isEmpty == false ||
        normalizedNotes.isEmpty == false ||
        normalizedURL.isEmpty == false ||
        normalizedListName.isEmpty == false ||
        normalizedContactName.isEmpty == false ||
        normalizedImageReference.isEmpty == false ||
        tagLabels.isEmpty == false ||
        priority != .none ||
        dueDate != nil
    }

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedURL: String {
        urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedListName: String {
        listName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedContactName: String {
        assignedContactName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedImageReference: String {
        imageAttachmentReference.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var sanitizedTagLabels: [String] {
        var seen = Set<String>()

        return tagLabels
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert(ReminderTag.normalize($0)).inserted }
    }
}

enum ReminderDraftMapper {
    static func apply(
        _ draft: ReminderDraft,
        to task: TaskItem,
        availableLists: [ReminderList],
        availableTags: [ReminderTag],
        in modelContext: ModelContext
    ) {
        task.taskTitle = draft.normalizedTitle
        task.notes = draft.normalizedNotes
        task.reminderURL = draft.normalizedURL
        task.priority = draft.priority
        task.assignedContactName = draft.normalizedContactName.nilIfBlank
        task.imageAttachmentReference = draft.normalizedImageReference.nilIfBlank
        if draft.hasTime, let date = draft.dueDate {
            task.dueDate = date
        } else {
            task.dueDate = draft.dueDate.map { Calendar.current.startOfDay(for: $0) }
        }
        task.reminderList = resolvedList(
            from: draft.normalizedListName,
            availableLists: availableLists,
            in: modelContext
        )
        task.tags = resolvedTags(
            from: draft.sanitizedTagLabels,
            availableTags: availableTags,
            in: modelContext
        )
    }

    private static func resolvedList(
        from draftListName: String,
        availableLists: [ReminderList],
        in modelContext: ModelContext
    ) -> ReminderList {
        let requestedName = draftListName.isEmpty ? ReminderDefaults.defaultListName : draftListName

        if let existing = availableLists.first(where: { $0.name.compare(requestedName, options: .caseInsensitive) == .orderedSame }) {
            return existing
        }

        let list = ReminderList(name: requestedName)
        modelContext.insert(list)
        return list
    }

    private static func resolvedTags(
        from labels: [String],
        availableTags: [ReminderTag],
        in modelContext: ModelContext
    ) -> [ReminderTag] {
        labels.map { label in
            let normalized = ReminderTag.normalize(label)

            if let existing = availableTags.first(where: { $0.normalizedLabel == normalized }) {
                return existing
            }

            let tag = ReminderTag(label: label)
            modelContext.insert(tag)
            return tag
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
