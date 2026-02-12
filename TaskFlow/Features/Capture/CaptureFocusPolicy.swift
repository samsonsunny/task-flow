import Foundation

struct CaptureFocusPolicy {
    static let quickReturnThreshold: TimeInterval = 60
    static let longIdleThreshold: TimeInterval = 60 * 30

    static func shouldAutoFocus(
        isListEmpty: Bool,
        didDismissKeyboardThisSession: Bool,
        didScrollBeforeTyping: Bool,
        lastTaskAddedAt: Date?,
        lastFocusedAt: Date?,
        lastBackgroundedAt: Date?,
        now: Date = Date()
    ) -> Bool {
        if didDismissKeyboardThisSession || didScrollBeforeTyping {
            return false
        }

        if isListEmpty {
            return true
        }

        if let lastBackgroundedAt {
            let idleTime = now.timeIntervalSince(lastBackgroundedAt)
            if idleTime < quickReturnThreshold {
                return true
            }

            if idleTime >= longIdleThreshold {
                return true
            }
        }

        if let lastTaskAddedAt, wasInPreviousSession(lastEventAt: lastTaskAddedAt, lastBackgroundedAt: lastBackgroundedAt) {
            return true
        }

        if let lastFocusedAt, wasInPreviousSession(lastEventAt: lastFocusedAt, lastBackgroundedAt: lastBackgroundedAt) {
            return true
        }

        return false
    }

    private static func wasInPreviousSession(lastEventAt: Date, lastBackgroundedAt: Date?) -> Bool {
        guard let lastBackgroundedAt else {
            return true
        }

        return lastEventAt <= lastBackgroundedAt
    }
}
