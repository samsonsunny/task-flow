import SwiftUI

/// Provides a centralized source for all colors used in the application.
/// All colors MUST be sourced from here to ensure visual consistency.
struct AppColors {
    // Backgrounds / Surfaces
    static let appBackground: Color = Color("appBackground")
    static let secondaryBackground: Color = Color("secondaryBackground")

    static let primaryAction: Color = Color("primaryAction")
    static let primaryActionPressed: Color = Color("primaryActionPressed")
    static let surface: Color = Color("surface")
    static let surfaceElevated: Color = Color("surfaceElevated")

    // Translucent fills (e.g. pressed states)
    static let fillSubtle: Color = Color("fillSubtle")

    // Text
    static let textPrimary: Color = Color("textPrimary")
    static let textSecondary: Color = Color("textSecondary")
    static let textDisabled: Color = Color("textDisabled")

    static let textOnPrimaryAction: Color = Color("textOnPrimaryAction")

    // Borders / Dividers
    static let border: Color = Color("border")
    static let borderSubtle: Color = Color("borderSubtle")
    static let divider: Color = Color("divider")

    // Status colors are intentionally grayscale in this app's design system.
    static let success: Color = Color("success")
    static let warning: Color = Color("warning")
    static let error: Color = Color("error")
}
