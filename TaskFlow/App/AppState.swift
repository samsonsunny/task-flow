import SwiftUI
import SwiftData

@Observable
final class AppState {
    private(set) var mutationCount: Int = 0

    func notifyMutation() {
        mutationCount += 1
    }
}
