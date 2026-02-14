import SwiftUI

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppTheme.spacing.md)
            .background(AppTheme.colors.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radius.large)
                    .stroke(AppTheme.colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.large))
    }
}

#Preview {
    CardView {
        VStack {
            Text("Card Title")
                .font(AppTheme.fonts.title2)
            Text("This is some content inside a card.")
                .font(AppTheme.fonts.body)
        }
        .padding()
    }
    .padding()
}
