import SwiftUI
import SwiftData

enum CaptureTarget: Hashable {
    case segment(HomeSegment)
    case list(ReminderList.ID)
}

struct CaptureHost<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    let target: CaptureTarget
    private let content: Content

    @State private var captureViewModel: CaptureBarViewModel?
    @State private var refreshTimer: Timer?

    init(target: CaptureTarget, @ViewBuilder content: () -> Content) {
        self.target = target
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            content
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let vm = captureViewModel {
                CaptureBar(
                    onCommit: { text, notes in
                        vm.commit(
                            text: text,
                            notes: notes,
                            target: target,
                            overrideDate: appState.pendingCaptureDate
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
                .onChange(of: appState.pendingCaptureFocus) { _, pending in
                    if pending, appState.consumeCaptureFocus() {
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