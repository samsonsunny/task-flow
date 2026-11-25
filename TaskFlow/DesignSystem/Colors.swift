import SwiftUI

/// Semantic color tokens shared by every surface.
///
/// Views must source colors from here (and from nowhere else) so Light Mode, Dark Mode,
/// and accessibility contrast stay consistent. Tokens map to system semantic colors, which
/// is what native iOS apps use instead of hard-coded values.
struct AppColors {
    // Backgrounds / surfaces
    static let appBackground: Color = Color(.systemGroupedBackground)
    static let pageBackground: Color = appBackground
    static let secondaryBackground: Color = Color(.secondarySystemGroupedBackground)
    static let background: Color = Color(.systemBackground)
    static let surface: Color = Color(.systemBackground)
    /// Background for grouped content: task cards, calendars, and inset rows.
    static let groupedSurface: Color = Color(.secondarySystemGroupedBackground)
    static let surfaceElevated: Color = Color(.secondarySystemBackground)
    static let fillSubtle: Color = Color(.systemFill)

    // Accent / actions
    static let tint: Color = .accentColor
    static let primaryAction: Color = .accentColor
    static let primaryActionPressed: Color = Color(.systemFill)

    // Text
    static let textPrimary: Color = .primary
    static let textSecondary: Color = Color(.secondaryLabel)
    static let textTertiary: Color = Color(.tertiaryLabel)
    static let textDisabled: Color = Color(.placeholderText)
    static let textOnPrimaryAction: Color = .white
    static let textOnTint: Color = .white

    // Borders / dividers
    static let border: Color = Color(.separator)
    static let borderSubtle: Color = Color(.separator)
    static let divider: Color = Color(.separator)

    // Status
    static let success: Color = .green
    static let warning: Color = .orange
    static let error: Color = .red
}
