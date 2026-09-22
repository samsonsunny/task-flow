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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppState.self) private var appState

    @State private var selectedDestination: SidebarDestination? = {
        if ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_UPCOMING") {
            return .upcoming
        }
        return .today
    }()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var captureViewModel: CaptureBarViewModel?
    @State private var refreshTimer: Timer?
    @State private var isOverviewFrontmost = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ListsSidebarView(selection: $selectedDestination)
                .onAppear { isOverviewFrontmost = true }
                .onDisappear { isOverviewFrontmost = false }
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.prominentDetail)
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let vm = captureViewModel {
                captureBarDock(vm: vm, target: currentCaptureTarget)
            }
        }
        .onAppear {
            if captureViewModel == nil {
                captureViewModel = CaptureBarViewModel(modelContext: modelContext)
            }
            captureViewModel?.refreshNow()
            scheduleMinuteAlignedTimer()
            if !appState.hasAutoFocusedOnce {
                captureViewModel?.isFocusingCapture = true
                appState.markAutoFocusedOnce()
            }
            if appState.consumeCaptureFocus() {
                captureViewModel?.isFocusingCapture = true
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        .onChange(of: appState.pendingCaptureDate) { _, new in
            guard new != nil else { return }
            captureViewModel?.text = ""
            captureViewModel?.isFocusingCapture = true
        }
    }

    private var currentCaptureTarget: CaptureTarget {
        if horizontalSizeClass == .compact && isOverviewFrontmost {
            return .inbox
        }
        switch selectedDestination {
        case .none, .some(.today):
            return .segment(.today)
        case .some(.tomorrow):
            return .segment(.tomorrow)
        case .some(.upcoming):
            return .segment(.upcoming)
        case .some(.list(let listID)):
            return .list(listID)
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        switch selectedDestination ?? .today {
        case .today:
            destinationStack(title: HomeSegment.today.title) {
                TodayTabView()
            }
        case .tomorrow:
            destinationStack(title: HomeSegment.tomorrow.title) {
                TomorrowView()
            }
        case .upcoming:
            destinationStack(title: HomeSegment.upcoming.title) {
                UpcomingView()
            }
        case .list(let listID):
            NavigationStack {
                ListDetailView(listID: listID)
            }
        }
    }

    private func destinationStack<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack {
            content()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.large)
        }
    }

    private func captureBarDock(vm: CaptureBarViewModel, target: CaptureTarget) -> some View {
        captureBar(vm: vm, target: target)
            .frame(maxWidth: .infinity)
    }

    private func captureBar(vm: CaptureBarViewModel, target: CaptureTarget) -> some View {
        CaptureBar(
            viewModel: vm,
            onCommit: { text, notes in
                vm.commit(
                    text: text,
                    notes: notes,
                    target: target,
                    overrideDate: captureOverrideDate(for: target)
                )
                appState.pendingCaptureDate = nil
                vm.isFocusingCapture = false
                vm.refreshNow()
            },
            autofocusRequest: vm.isFocusingCapture
        )
    }

    private func captureOverrideDate(for target: CaptureTarget) -> Date? {
        if case .segment = target {
            return appState.pendingCaptureDate
        }
        return nil
    }

    private func scheduleMinuteAlignedTimer() {
        refreshTimer?.invalidate()
        guard let vm = captureViewModel else { return }
        let interval: TimeInterval = 60
        let now = Date().timeIntervalSinceReferenceDate
        let nextMinute = ceil(now / interval) * interval
        let delay = nextMinute - now

        let timer = Timer(
            fire: Date().addingTimeInterval(delay),
            interval: interval,
            repeats: true
        ) { _ in
            Task { @MainActor in
                vm.refreshNow()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
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