import SwiftUI

/// The app's typography hierarchy.
///
/// Every style is a semantic Dynamic Type style, so text scales with the user's
/// accessibility settings and follows the system's weight/leading in both Light and
/// Dark Mode. Call sites should use these names rather than fixed point sizes.
struct AppFont {
    static var largeTitle: Font { .largeTitle }
    static var largeTitleSemibold: Font { .largeTitle.weight(.semibold) }
    static var title: Font { .title.weight(.semibold) }
    static var title2: Font { .title2 }
    static var title3: Font { .title3.weight(.semibold) }

    static var headline: Font { .headline }
    static var headlineSemibold: Font { .headline.weight(.semibold) }
    static var body: Font { .body }
    static var bodySemibold: Font { .body.weight(.semibold) }
    static var subheadline: Font { .subheadline }
    static var subheadlineSemibold: Font { .subheadline.weight(.semibold) }

    /// Secondary metadata such as list names and due dates.
    static var footnote: Font { .footnote }
    static var footnoteSemibold: Font { .footnote.weight(.semibold) }
    static var caption: Font { .caption }
    static var captionSemibold: Font { .caption.weight(.semibold) }
    static var caption2: Font { .caption2 }
    static var caption2Semibold: Font { .caption2.weight(.semibold) }

    // Compatibility aliases for older call sites. They resolve to the same
    // Dynamic Type styles, so nothing renders at a fixed point size.
    static var display: Font { largeTitleSemibold }
    static var h1: Font { title }
    static var extraLargeIcon: Font { .largeTitle }
}
