import SwiftUI

/// Provides a centralized source for all font styles used in the application.
/// All fonts and text styles MUST use helpers and definitions from here.
struct AppFont {
    // Explicitly defined type scale from DesignRules.md (using static var for chainability)
    static var display: Font {
        .system(size: 32, weight: .semibold) // Line height 40 implied by design rules
    }

    static var largeTitle: Font { // Added for OnboardingView
        .largeTitle
    }
    static var largeTitleSemibold: Font {
        .largeTitle.weight(.semibold)
    }

    static var h1: Font { // Aligning with DesignRules H1
        .system(size: 24, weight: .semibold) // Line height 32 implied
    }

    static var title: Font {
        .system(size: 20, weight: .semibold) // Matches DesignRules.md H2
    }

    static var title2: Font { // Added for OnboardingView's Image font in cardContent
        .title2
    }

    static var headline: Font {
        .headline // Using system font as it's a semantic style
    }
    static var headlineSemibold: Font {
        .headline.weight(.semibold)
    }

    static var subheadline: Font { // Added for OnboardingView
        .subheadline
    }
    static var subheadlineSemibold: Font {
        .subheadline.weight(.semibold)
    }

    static var body: Font {
        .body // Using system font as it's a semantic style
    }

    static var caption: Font {
        .caption // Using system font as it's a semantic style
    }
    static var captionSemibold: Font {
        .caption.weight(.semibold)
    }
    
    static var caption2: Font { // Added for TaskListView
        .caption2
    }
    
    // Custom font size for extra large icons, derived from EmptyStateView.swift
    static var extraLargeIcon: Font {
        .system(size: 80)
    }

    // You can add custom fonts here if needed
    // Example for a custom font:
    /*
    static func customBody(weight: Font.Weight = .regular) -> Font {
        .custom("YourCustomFontName", size: 16)
            .weight(weight)
    }
    */
}
