import SwiftUI

/// Centralizes the application's overall theme properties.
/// This can be expanded to manage light/dark modes, accessibility settings, etc.
struct AppTheme {
    // References to other design system components
    static let colors = AppColors.self
    static let fonts = AppFont.self
    static let radius = AppRadius.self

    /// Approximate visual height of the capture bar (including its bottom breathing room).
    static let captureBarHeight: CGFloat = 0
    /// Bottom scroll-content clearance that keeps the last row resting above the bar.
    static let captureBarClearance: CGFloat = 0
}

/// User-selectable appearance, persisted through `@AppStorage`. `nil` follows the system.
enum AppAppearance: String, CaseIterable, Identifiable {
    static let storageKey = "app_appearance"

    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
