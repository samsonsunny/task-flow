import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    /// Reconciliation must finish before any `@Query` in the tree reads area state —
    /// otherwise Home can render a third synced area, or an `AppState` reference to a group
    /// the merge is about to delete. Gating the root on the pass makes the ordering a
    /// property of the structure rather than a hope about `onAppear` timing.
    @State private var isReconciled = false

    var body: some View {
        Group {
            if isReconciled {
                MainTabView()
            } else {
                Color.clear
            }
        }
        .task {
            migrateGlobalInboxToFirstGroup(in: modelContext)
            reconcileLockedAreas(in: modelContext)
            backfillSortOrdersIfNeeded(in: modelContext)
            isReconciled = true
        }
    }
}

#Preview("Empty State") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedDefaultAreas(in: container.mainContext)
    return ContentView()
        .modelContainer(container)
        .environment(AppState())
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return ContentView()
        .modelContainer(container)
        .environment(AppState())
}
