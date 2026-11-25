import SwiftUI

/// Shared system spacing scale. Native layouts use multiples of 4 pt and let
/// Dynamic Type grow text instead of shrinking it.
struct AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let screenHorizontal: CGFloat = 20
    static let rowVertical: CGFloat = 12
    static let minimumTapTarget: CGFloat = 44
}

/// Centralizes the application's overall theme properties.
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
