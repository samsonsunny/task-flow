import Foundation
import SwiftUI

/// Provides a centralized access point for all design system components.
/// Use AppTheme.colors, AppTheme.spacing, etc., to ensure consistency.
struct AppTheme {
    static let colors = AppColors.self // Access AppColors properties like AppTheme.colors.primary
    static let fonts = AppFont.self // Access AppFont properties like AppTheme.fonts.body
    static let spacing = Spacing.self // Access Spacing properties like AppTheme.spacing.md
    static let radius = AppRadius.self // Access AppRadius properties like AppTheme.radius.large
    static let shadows = AppShadow.self // Access AppShadow properties like AppTheme.shadows.elevation1
}
