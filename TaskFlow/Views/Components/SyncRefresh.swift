import SwiftUI
import SwiftData

extension View {
    func refreshOnModelContextSave(_ action: @escaping () -> Void) -> some View {
        onReceive(
            NotificationCenter.default.publisher(for: ModelContext.didSave),
            perform: { _ in action() }
        )
    }
}