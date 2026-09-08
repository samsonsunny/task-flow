import SwiftUI
import SwiftData

enum HomeSegment: String, CaseIterable, Identifiable, Hashable {
    case today
    case tomorrow
    case upcoming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .upcoming: return "Upcoming"
        }
    }
}

enum SidebarDestination: Hashable {
    case today
    case tomorrow
    case upcoming
    case list(ReminderList.ID)
}

struct MainTabView: View {
    @State private var selectedDestination: SidebarDestination? = {
        if ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_UPCOMING") {
            return .upcoming
        }
        return .today
    }()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ListsSidebarView(selection: $selectedDestination)
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.prominentDetail)
    }

    @ViewBuilder
    private var detailColumn: some View {
        switch selectedDestination ?? .today {
        case .today:
            timePage(for: .today)
        case .tomorrow:
            timePage(for: .tomorrow)
        case .upcoming:
            timePage(for: .upcoming)
        case .list(let listID):
            CaptureHost(target: .list(listID)) {
                ListDetailView(listID: listID)
            }
        }
    }

    private func timePage(for segment: HomeSegment) -> some View {
        CaptureHost(target: .segment(segment)) {
            page(for: segment)
                .navigationTitle(segment.title)
                .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private func page(for segment: HomeSegment) -> some View {
        switch segment {
        case .today:
            TodayTabView()
        case .tomorrow:
            TomorrowView()
        case .upcoming:
            UpcomingView()
        }
    }
}

#Preview("Empty State") {
    let container = TaskPreviewData.container()
    TaskPreviewData.ensureDefaultListExists(in: container.mainContext)
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