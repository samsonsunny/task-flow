import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@MainActor
struct CaptureBarViewModelTests {
    private func tasks(in context: ModelContext) -> [TaskItem] {
        (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
    }

    @Test func areaCaptureUsesThatAreasBucket() {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let groups = seedDefaultAreas(in: context)
        let personal = groups.first { $0.name == "Personal" }!
        let viewModel = CaptureBarViewModel(modelContext: context)

        viewModel.commit(
            text: "Personal task",
            notes: "",
            target: .area(personal.persistentModelID),
            selectedAreaID: personal.persistentModelID
        )

        #expect(tasks(in: context).first?.reminderList?.persistentModelID == personal.inboxBucket?.persistentModelID)
        #expect(tasks(in: context).first?.dueDate == nil)
    }

    /// The core scoping invariant: a Personal user must never have a task filed into Work,
    /// even when Work is positionally first.
    @Test func areaCaptureNeverFallsBackToTheOtherArea() {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let groups = seedDefaultAreas(in: context)
        let work = groups.first { $0.name == "Work" }!
        let personal = groups.first { $0.name == "Personal" }!
        let viewModel = CaptureBarViewModel(modelContext: context)

        viewModel.commit(
            text: "Must not land in Work",
            notes: "",
            target: .area(personal.persistentModelID),
            selectedAreaID: personal.persistentModelID
        )

        let list = tasks(in: context).first?.reminderList
        #expect(list?.persistentModelID == personal.inboxBucket?.persistentModelID)
        #expect(list?.persistentModelID != work.inboxBucket?.persistentModelID)
        #expect(list?.group?.persistentModelID == personal.persistentModelID)
    }

    @Test func areaCaptureSeedsLockedAreasInEmptyStore() {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let viewModel = CaptureBarViewModel(modelContext: context)

        viewModel.commit(text: "First task", notes: "", target: .segment(.today), selectedAreaID: nil)

        let groups = (try? context.fetch(
            FetchDescriptor<ReminderListGroup>(sortBy: [SortDescriptor(\.sortOrder)])
        )) ?? []
        let work = groups.first { $0.name == "Work" }
        let personal = groups.first { $0.name == "Personal" }

        #expect(groups.count == 2)
        #expect(work?.inboxBucket != nil)
        #expect(personal?.inboxBucket != nil)
        #expect(groups.allSatisfy { $0.isLocked })
        #expect(tasks(in: context).first?.reminderList?.persistentModelID == work?.inboxBucket?.persistentModelID)
    }

    @Test func listCaptureKeepsSelectedList() {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Work", sortOrder: "a")
        let list = ReminderList(name: "Projects", group: group)
        context.insert(group)
        context.insert(list)
        try? context.save()
        let viewModel = CaptureBarViewModel(modelContext: context)

        viewModel.commit(
            text: "Project task",
            notes: "",
            target: .list(list.persistentModelID),
            selectedAreaID: group.persistentModelID
        )

        #expect(tasks(in: context).first?.reminderList?.persistentModelID == list.persistentModelID)
    }

    @Test func bucketCaptureUsesSelectedBucketByPointer() {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = ReminderListGroup(name: "Work", sortOrder: "a")
        let personal = ReminderListGroup(name: "Personal", sortOrder: "b")
        context.insert(work)
        context.insert(personal)
        let workBucket = makeBucket(for: work, in: context)
        let personalBucket = makeBucket(for: personal, in: context)
        try? context.save()
        let viewModel = CaptureBarViewModel(modelContext: context)

        viewModel.commit(
            text: "Personal task",
            notes: "",
            target: .list(personalBucket.persistentModelID),
            selectedAreaID: personal.persistentModelID
        )

        #expect(tasks(in: context).first?.reminderList?.persistentModelID == personalBucket.persistentModelID)
        #expect(tasks(in: context).first?.reminderList?.persistentModelID != workBucket.persistentModelID)
    }

    /// A time-view capture still resolves against the selected area, so browsing Today
    /// while Personal is selected cannot misfile.
    @Test func segmentCaptureUsesSelectedAreaBucket() {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let groups = seedDefaultAreas(in: context)
        let personal = groups.first { $0.name == "Personal" }!
        let viewModel = CaptureBarViewModel(modelContext: context)

        viewModel.commit(
            text: "Today task",
            notes: "",
            target: .segment(.today),
            selectedAreaID: personal.persistentModelID
        )

        let task = tasks(in: context).first
        #expect(task?.reminderList?.persistentModelID == personal.inboxBucket?.persistentModelID)
        #expect(task?.dueDate != nil)
    }
}
