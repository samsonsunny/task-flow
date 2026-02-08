import SwiftUI

/// Provides a centralized source for all colors used in the application.
/// All colors MUST be sourced from here to ensure visual consistency.
struct AppColors {
    // Semantic Colors derived from the old AppTheme.colors and system defaults
    static let background: Color = Color(UIColor.systemBackground)
    static let secondaryBackground: Color = Color(UIColor.secondarySystemBackground)
    static let primary: Color = Color("AccentColor") // Assumes AccentColor is defined in Assets.xcassets
    static let text: Color = Color.primary // System primary text color
    static let secondaryText: Color = Color.secondary
    static let danger: Color = Color.red
    static let success: Color = Color.green
    // Add other semantic colors here as needed
}
