//
//  AppTheme.swift
//  TaskFlow
//
//  Created by AI on 21-01-2026.
//

import SwiftUI

/// Centralized design tokens for the app (colors, typography, spacing).
/// Keep lightweight and dependency-free so all views can import it.
public enum AppTheme {
    // MARK: - Colors
    public enum Colors {
        /// Primary background color for app surfaces.
        public static var background: Color {
            Color(UIColor.systemBackground)
        }

        /// Secondary background for grouped or inset areas.
        public static var secondaryBackground: Color {
            Color(UIColor.secondarySystemBackground)
        }

        /// Primary accent color used for emphasis and interactive elements.
        public static var primary: Color {
            Color.accentColor
        }

        /// Secondary text color for captions and labels.
        public static var secondaryText: Color {
            Color.secondary
        }

        /// Color for destructive actions.
        public static var danger: Color {
            Color.red
        }
        
        /// Primary text color for readable content.
        public static var text: Color {
            Color.primary
        }

        /// Success color for completed states and positive feedback.
        public static var success: Color {
            Color.green
        }
    }

    // MARK: - Typography
    public enum Typography {
        /// Large title style for prominent text inputs and headers.
        public static var title: Font { .title2.weight(.semibold) }
        
        /// Headline style for section headers and list titles.
        public static var headline: Font { .headline }

        /// Standard body text.
        public static var body: Font { .body }
        
        /// Caption style for field labels and hints.
        public static var caption: Font { .caption }
    }

    // MARK: - Spacing
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 28
    }
}
