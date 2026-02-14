import SwiftUI

/// Provides a centralized source for all colors used in the application.
/// All colors MUST be sourced from here to ensure visual consistency.
struct AppColors {
    static let primaryAction: Color = Color("primaryAction")
    static let primaryActionPressed: Color = Color("primaryActionPressed")
    static let appBackground: Color = Color("appBackground")
    static let secondaryBackground: Color = Color("secondaryBackground")
    static let surface: Color = Color("surface")
    static let surfaceElevated: Color = Color("surfaceElevated")
    static let textPrimary: Color = Color("textPrimary")
    static let textSecondary: Color = Color("textSecondary")
    static let textDisabled: Color = Color("textDisabled")
    static let border: Color = Color("border")
    static let divider: Color = Color("divider")
    static let success: Color = Color("success")
    static let warning: Color = Color("warning")
    static let error: Color = Color("error")
}
