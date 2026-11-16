import SwiftUI
import SwiftData

/// Today tab container.
///
/// The scheduled calendar is the tab's root, but the tab lands on the Today task
/// list by default. Popping back reveals the calendar, which hides the tab bar and
/// shows only Today and add buttons in the bottom toolbar. The Today button (or
/// re-selecting the tab) pushes the Today task list again.
struct TodayNavigationStackView: View {
    @Environment(AppState.self) private var appState
    @State private var path = NavigationPath([TodayRoute.today])
    @State private var lastHandledTodayResetID = 0

    var body: some View {
        NavigationStack(path: $path) {
            ScheduledTasksView(onShowToday: showToday)
                .navigationDestination(for: TodayRoute.self) { route in
                    switch route {
                    case .today:
                        TodayTaskListView(embedInNavigationStack: false)
                    }
                }
        }
        .background(TabBarVisibilityAdjuster(hidden: path.isEmpty).frame(width: 0, height: 0))
        .onAppear {
            lastHandledTodayResetID = appState.todayResetRequestID
        }
        .onChange(of: appState.todayResetRequestID) { _, _ in
            handleTodayResetIfNeeded()
        }
    }

    private func handleTodayResetIfNeeded() {
        guard appState.todayResetRequestID != lastHandledTodayResetID else { return }
        lastHandledTodayResetID = appState.todayResetRequestID
        showToday()
    }

    private func showToday() {
        if path.isEmpty {
            path.append(TodayRoute.today)
        } else {
            path = NavigationPath([TodayRoute.today])
        }
    }
}

private enum TodayRoute: Hashable {
    case today
}

#Preview {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return TodayNavigationStackView()
        .modelContainer(container)
        .environment(AppState())
}
