import SwiftUI
import SwiftData

enum HomeSegment: String, CaseIterable, Identifiable, Hashable {
    case organize
    case today
    case tomorrow
    case upcoming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .organize: return "Inbox"
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .upcoming: return "Upcoming"
        }
    }
}

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var selectedSegment: HomeSegment = {
        if ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_UPCOMING") {
            return .upcoming
        }
        return .today
    }()
    @State private var navigationPath = NavigationPath()
    @State private var captureViewModel: CaptureBarViewModel?
    @State private var refreshTimer: Timer?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            content(for: selectedSegment, headerAccessory: { AnyView(segmentPicker) })
                .navigationTitle("My Tasks")
                .navigationBarTitleDisplayMode(.large)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let vm = captureViewModel {
                CaptureBar(
                    onCommit: { text, notes in
                        vm.commit(
                            text: text,
                            notes: notes,
                            for: selectedSegment,
                            overrideDate: appState.pendingCaptureDate,
                            activeListID: appState.activeListID
                        )
                        appState.pendingCaptureDate = nil
                        vm.isFocusingCapture = false
                        vm.refreshNow()
                    },
                    autofocusRequest: vm.isFocusingCapture
                )
                .id(appState.pendingCaptureDate)
                .onChange(of: appState.pendingCaptureDate) { _, new in
                    if new != nil {
                        vm.isFocusingCapture = true
                    }
                }
            }
        }
        .onAppear {
            if captureViewModel == nil {
                captureViewModel = CaptureBarViewModel(modelContext: modelContext)
            }
            captureViewModel?.refreshNow()
            scheduleMinuteAlignedTimer()
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        .onChange(of: selectedSegment) { _, _ in
            navigationPath = NavigationPath()
            appState.pendingCaptureDate = nil
            captureViewModel?.refreshNow()
        }
    }

    private var segmentPicker: some View {
        Picker("View", selection: $selectedSegment) {
            ForEach(HomeSegment.allCases) { segment in
                Text(segment.title)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .accessibilityIdentifier("home-segment-picker")
    }

    @ViewBuilder
    private func content(for segment: HomeSegment, headerAccessory: (() -> AnyView)?) -> some View {
        switch segment {
        case .organize:
            ListsTabView(headerAccessory: headerAccessory)
        case .today:
            TodayTabView(headerAccessory: headerAccessory)
        case .tomorrow:
            TomorrowView(headerAccessory: headerAccessory)
        case .upcoming:
            UpcomingView(headerAccessory: headerAccessory)
        }
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