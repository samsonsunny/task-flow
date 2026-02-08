import SwiftUI

/// Provides a centralized source for all shadow styles used in the application.
/// All shadows MUST use predefined constants from here.
struct AppShadow {
    static let elevation1: ShadowStyle = ShadowStyle(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2) // Lighter, smaller blur
    static let elevation2: ShadowStyle = ShadowStyle(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)  // Matches TaskDetailView original shadow
    static let elevation3: ShadowStyle = ShadowStyle(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6) // Stronger

    // Custom shadow for InlineAddTaskRow
    static let elevationInlineAddTask: ShadowStyle = ShadowStyle(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)

    // Helper struct to define shadow parameters
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// Example usage as a View extension (optional, but good practice)
extension View {
    func appShadow(_ style: AppShadow.ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
