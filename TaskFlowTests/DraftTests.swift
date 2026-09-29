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
@Test func reminderDraftMapperResolvesBucketByIDAndReusesExistingTags() throws {
    let container = TaskPreviewData.container()
    let context = container.mainContext

    let groups = seedDefaultAreas(in: context)
    let bucket = groups[0].inboxBucket!

    let existingTag = ReminderTag(label: "Home")
    context.insert(existingTag)

    let draft = ReminderDraft(
        title: "Plan trip",
        notes: "Passport renewal",
        urlString: "https://example.com",
        listName: "Inbox",
        listID: bucket.persistentModelID,
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
        availableLists: [bucket],
        availableTags: [existingTag],
        in: context
    )

    #expect(task.safeTitle == "Plan trip")
    #expect(task.notes == "Passport renewal")
    #expect(task.reminderURL == "https://example.com")
    #expect(task.reminderList?.persistentModelID == bucket.persistentModelID)
    #expect(task.priority == .medium)
    #expect(task.assignedContactName == "Alex")
    #expect(task.imageAttachmentReference == "boarding-pass.png")
    #expect(task.tagLabels == ["Home", "Urgent"])
    #expect(task.tagsArray.contains(where: { $0 === existingTag }))
}

@MainActor
@Test func reminderDraftMapperFallsBackByNameWhenNoID() throws {
    let container = TaskPreviewData.container()
    let context = container.mainContext

    let existingList = ReminderList(name: "Groceries")
    existingList.group = ReminderListGroup(name: "Work")
    context.insert(existingList)
    context.insert(existingList.group!)

    let draft = ReminderDraft(
        title: "Buy milk",
        notes: "",
        urlString: "",
        listName: "Groceries",
        tagLabels: [],
        priority: .none,
        assignedContactName: "",
        imageAttachmentReference: "",
        dueDate: nil
    )

    let task = TaskItem()
    ReminderDraftMapper.apply(
        draft,
        to: task,
        availableLists: [existingList],
        availableTags: [],
        in: context
    )

    #expect(task.reminderList?.persistentModelID == existingList.persistentModelID)
}
