import SwiftData

struct CompletionUndo: Identifiable {
    let task: TaskItem

    var id: PersistentIdentifier {
        task.persistentModelID
    }
}
