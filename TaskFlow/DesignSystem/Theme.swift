import SwiftUI

/// Centralizes the application's overall theme properties.
/// This can be expanded to manage light/dark modes, accessibility settings, etc.
struct AppTheme {
    // References to other design system components
    static let colors = AppColors.self
//    static let spacing = Spacing.self
    static let fonts = AppFont.self
    static let radius = AppRadius.self

    // Example of a global modifier or setup function
    static func setup() {
        // Here you could apply global styles or configure appearance
        // For example:
        // UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont.systemFont(ofSize: 34, weight: .bold)]
        // This setup will depend on the app's architecture and needs.
    }
}
