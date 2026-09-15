import SwiftUI

/// Centralizes the application's overall theme properties.
/// This can be expanded to manage light/dark modes, accessibility settings, etc.
struct AppTheme {
    // References to other design system components
    static let colors = AppColors.self
    static let fonts = AppFont.self
    static let radius = AppRadius.self

    /// Approximate visual height of the capture bar (including its bottom breathing room).
    static let captureBarHeight: CGFloat = 60
    /// Bottom scroll-content clearance that keeps the last row resting above the bar.
    static let captureBarClearance: CGFloat = 72
}
