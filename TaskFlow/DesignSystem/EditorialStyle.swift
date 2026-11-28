import SwiftUI

enum EditorialStyle {
    static let horizontalPadding: CGFloat = 20
    static let eyebrowTracking: CGFloat = 1.4

    static func eyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.footnote.weight(.semibold))
            .tracking(eyebrowTracking)
            .foregroundStyle(.secondary)
    }

    static func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
    }
}

struct EditorialSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            EditorialStyle.eyebrow(title)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .textCase(nil)
        .accessibilityAddTraits(.isHeader)
    }
}
