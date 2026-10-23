import SwiftUI

struct UndoToast: View {
    let title: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.colors.success.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.colors.success)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Completed")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.textPrimary)

                if !title.isEmpty {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(AppTheme.colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 12)

            Button {
                Haptics.impact(.light)
                onUndo()
            } label: {
                Text("Undo")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.tint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AppTheme.colors.tint.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("undo-completion-button")
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(AppTheme.colors.borderSubtle)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}
