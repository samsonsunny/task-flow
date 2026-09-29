import SwiftUI
import SwiftData

/// The app's single navigation stack.
///
/// Replaces the former `NavigationSplitView` + sidebar: Home is now the root, owns all
/// navigation state in one `path`, and pushes every destination onto it. There is no second
/// stack and no sidebar, so the same push/pop model holds on iPhone, iPad, and Mac.
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    var body: some View {
        // Home owns the single `NavigationStack` and its `path`; the root only hosts it.
        HomeView()
            .tint(AppTheme.colors.primaryAction)
            .onOpenURL { url in
                handle(url)
            }
    }

    private func handle(_ url: URL) {
        switch url.host {
        case "tomorrow":
            appState.pendingCaptureDate = Calendar.current.date(
                byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())
            )
        case "upcoming":
            appState.pendingCaptureDate = ReminderSegmentLogic.upcomingStart(now: Date())
        default:
            break
        }
    }
}

#Preview("Empty State") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedDefaultAreas(in: container.mainContext)
    return MainTabView()
        .modelContainer(container)
        .environment(AppState())
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return MainTabView()
        .modelContainer(container)
        .environment(AppState())
}
