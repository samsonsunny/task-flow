import SwiftUI
import UIKit

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
    static var textPrimary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 1, green: 1, blue: 1, alpha: 1)
                : UIColor(red: 0x1C/255, green: 0x1C/255, blue: 0x1E/255, alpha: 1)
        })
    }

    static var textSecondary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0xAE/255, green: 0xAE/255, blue: 0xB2/255, alpha: 1)
                : UIColor(red: 0x6E/255, green: 0x6E/255, blue: 0x73/255, alpha: 1)
        })
    }

    static var textTertiary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0x63/255, green: 0x63/255, blue: 0x66/255, alpha: 1)
                : UIColor(red: 0xAE/255, green: 0xAE/255, blue: 0xB2/255, alpha: 1)
        })
    }

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

    // Dynamic adaptive colors
    static var reminderCircle: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0x63/255, green: 0x63/255, blue: 0x66/255, alpha: 1)
                : UIColor(red: 0x8E/255, green: 0x8E/255, blue: 0x93/255, alpha: 1)
        })
    }

    static var addReminderCircle: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0x8E/255, green: 0x8E/255, blue: 0x93/255, alpha: 1)
                : UIColor(red: 0xB0/255, green: 0xB0/255, blue: 0xB5/255, alpha: 1)
        })
    }
}
