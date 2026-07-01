import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@Test func reminderDraftSaveStateTracksMeaningfulContent() {
    var draft = ReminderDraft.empty
    #expect(!draft.hasMeaningfulContent)

    draft.title = "Buy milk"
    #expect(draft.hasMeaningfulContent)

    draft.title = ""
    #expect(!draft.hasMeaningfulContent)

    draft.priority = .high
    #expect(draft.hasMeaningfulContent)
}

@MainActor
@Test func reminderDraftMapperUsesDefaultListAndReusesExistingTags() throws {
    let container = TaskPreviewData.container()
    let context = container.mainContext

    let existingTag = ReminderTag(label: "Home")
    let existingList = ReminderList(name: ReminderDefaults.defaultListName)
    context.insert(existingTag)
    context.insert(existingList)

    let draft = ReminderDraft(
        title: "Plan trip",
        notes: "Passport renewal",
        urlString: "https://example.com",
        listName: "",
        tagLabels: ["Home", "Urgent"],
        priority: .medium,
        assignedContactName: "Alex",
        imageAttachmentReference: "boarding-pass.png",
        dueDate: makeDate(year: 2026, month: 5, day: 16, calendar: makeCalendar())
    )

    let task = TaskItem()
    ReminderDraftMapper.apply(
        draft,
        to: task,
        availableLists: [existingList],
        availableTags: [existingTag],
        in: context
    )

    #expect(task.safeTitle == "Plan trip")
    #expect(task.notes == "Passport renewal")
    #expect(task.reminderURL == "https://example.com")
    #expect(task.listName == ReminderDefaults.defaultListName)
    #expect(task.priority == .medium)
    #expect(task.assignedContactName == "Alex")
    #expect(task.imageAttachmentReference == "boarding-pass.png")
    #expect(task.tagLabels == ["Home", "Urgent"])
    #expect(task.tags.contains(where: { $0 === existingTag }))
}
