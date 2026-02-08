import Foundation // For CGFloat

/// Provides a centralized source for all spacing values used in the application.
/// All spacing values MUST be sourced from here to ensure visual consistency and adherence to the 8-pt grid.
struct Spacing {
    static let xxs: CGFloat = 4

    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48

    // Add more as needed, maintaining the 8-pt grid system or multiples of 4
}