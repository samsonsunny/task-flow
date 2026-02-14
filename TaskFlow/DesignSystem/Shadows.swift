import SwiftUI

/// Provides a centralized source for all shadow styles used in the application.
/// All shadows MUST use predefined constants from here.
struct AppShadow {
    // Locked color system forbids decorative/colored shadows.
    static let elevation1: ShadowStyle = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
    static let elevation2: ShadowStyle = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
    static let elevation3: ShadowStyle = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)

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
