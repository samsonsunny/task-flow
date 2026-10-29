import SwiftUI

/// Provides a centralized source for all colors used in the application.
/// All colors MUST be sourced from here to ensure visual consistency.
struct AppColors {
    // Backgrounds / Surfaces
    static let appBackground: Color = Color(.systemGroupedBackground)
    /// Page background: #F2F3F5 in light mode, #000000 in dark mode.
    static let pageBackground: Color = adaptiveColor(
        light: UIColor(red: 0xF2 / 255, green: 0xF3 / 255, blue: 0xF5 / 255, alpha: 1),
        dark: .black
    )
    static let secondaryBackground: Color = Color(.secondarySystemGroupedBackground)
    static let background: Color = Color(.systemBackground)

    static let tint: Color = .accentColor

    static let primaryAction: Color = .primary
    static let primaryActionPressed: Color = Color(.systemFill)
    static let surface: Color = Color(.systemBackground)
    static let surfaceElevated: Color = Color(.secondarySystemBackground)

    // Translucent fills (e.g. pressed states)
    static let fillSubtle: Color = Color(.systemFill)

    // Text
    static let textPrimary: Color = .primary
    static let textSecondary: Color = Color(.secondaryLabel)
    static let textTertiary: Color = Color(.tertiaryLabel)

    static let textDisabled: Color = Color(.placeholderText)

    static let textOnPrimaryAction: Color = Color(.systemBackground)
    static let textOnTint: Color = .white

    // Borders / Dividers
    static let border: Color = Color(.separator)
    static let borderSubtle: Color = Color(.separator).opacity(0.5)
    static let divider: Color = Color(.separator)
    /// Card border: #E5E5EA in light mode, #303034 in dark mode.
    static let cardBorder: Color = adaptiveColor(
        light: UIColor(red: 0xE5 / 255, green: 0xE5 / 255, blue: 0xEA / 255, alpha: 1),
        dark: UIColor(red: 0x30 / 255, green: 0x30 / 255, blue: 0x34 / 255, alpha: 1)
    )

    // Status
    static let success: Color = .green
    static let warning: Color = .orange
    static let error: Color = .red

    private static func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? dark.resolvedColor(with: traits)
                : light.resolvedColor(with: traits)
        })
    }
}
