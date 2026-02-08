import Foundation // For CGFloat

/// Provides a centralized source for all corner radius values used in the application.
/// All corner radius values MUST be sourced from here.
struct AppRadius {
    static let none: CGFloat = 0
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
    static let full: CGFloat = 999 // Example for a pill-shaped button, adjust as needed
    // Add more as needed
}
