import SwiftUI
import Combine

final class CaptureSessionState: ObservableObject {
    @Published var didDismissKeyboardThisSession = false
    @Published var didScrollBeforeTyping = false
    @Published var didTypeInSession = false

    @AppStorage("capture_lastTaskAddedAt") private var lastTaskAddedAtStorage: Double = 0
    @AppStorage("capture_lastFocusedAt") private var lastFocusedAtStorage: Double = 0
    @AppStorage("capture_lastBackgroundedAt") private var lastBackgroundedAtStorage: Double = 0

    var lastTaskAddedAt: Date? {
        date(from: lastTaskAddedAtStorage)
    }

    var lastFocusedAt: Date? {
        date(from: lastFocusedAtStorage)
    }

    var lastBackgroundedAt: Date? {
        date(from: lastBackgroundedAtStorage)
    }

    func recordTaskAdded(at date: Date = Date()) {
        lastTaskAddedAtStorage = date.timeIntervalSince1970
    }

    func recordFocused(at date: Date = Date()) {
        lastFocusedAtStorage = date.timeIntervalSince1970
    }

    func recordBackgrounded(at date: Date = Date()) {
        lastBackgroundedAtStorage = date.timeIntervalSince1970
    }

    func markTypedInSession() {
        didTypeInSession = true
    }

    func markScrolledBeforeTyping() {
        guard !didTypeInSession else { return }
        didScrollBeforeTyping = true
    }

    func markKeyboardDismissed() {
        didDismissKeyboardThisSession = true
    }

    func resetSessionFlags() {
        didDismissKeyboardThisSession = false
        didScrollBeforeTyping = false
        didTypeInSession = false
    }

    func handleScenePhase(_ phase: ScenePhase, now: Date = Date()) {
        switch phase {
        case .background:
            recordBackgrounded(at: now)
        case .active:
            if shouldResetForLongIdle(now: now) {
                resetSessionFlags()
            }
        default:
            break
        }
    }

    func shouldAutoFocus(isListEmpty: Bool, now: Date = Date()) -> Bool {
        CaptureFocusPolicy.shouldAutoFocus(
            isListEmpty: isListEmpty,
            didDismissKeyboardThisSession: didDismissKeyboardThisSession,
            didScrollBeforeTyping: didScrollBeforeTyping,
            lastTaskAddedAt: lastTaskAddedAt,
            lastFocusedAt: lastFocusedAt,
            lastBackgroundedAt: lastBackgroundedAt,
            now: now
        )
    }

    private func shouldResetForLongIdle(now: Date) -> Bool {
        guard let lastBackgroundedAt else { return false }
        return now.timeIntervalSince(lastBackgroundedAt) >= CaptureFocusPolicy.longIdleThreshold
    }

    private func date(from storage: Double) -> Date? {
        guard storage > 0 else { return nil }
        return Date(timeIntervalSince1970: storage)
    }
}

