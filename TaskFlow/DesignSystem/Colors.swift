import SwiftUI

/// Provides a centralized source for all colors used in the application.
/// All colors MUST be sourced from here to ensure visual consistency.
struct AppColors {
    // Backgrounds / Surfaces
    static let appBackground: Color = Color(.systemGroupedBackground)
    static let secondaryBackground: Color = Color(.secondarySystemGroupedBackground)

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

    // Borders / Dividers
    static let border: Color = Color(.separator)
    static let borderSubtle: Color = Color(.separator).opacity(0.5)
    static let divider: Color = Color(.separator)

    // Status
    static let success: Color = .green
    static let warning: Color = .orange
    static let error: Color = .red
}
