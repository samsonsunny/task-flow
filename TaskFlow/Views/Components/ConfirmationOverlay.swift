import SwiftUI

/// A custom, app-controlled destructive confirmation.
///
/// Presented as an overlay rather than `confirmationDialog` so the position is ours and the
/// underlying list is never re-laid out while the system action sheet animates.
struct ConfirmationOverlay: View {
    let title: String
    let message: String
    let confirmTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 10) {
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.colors.textPrimary)

                    Button(role: .destructive) {
                        onConfirm()
                    } label: {
                        Text(confirmTitle)
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.colors.error)
                }
            }
            .frame(maxWidth: 320)
            .padding(22)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(AppTheme.colors.borderSubtle)
            }
            .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 10)
            .padding(24)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity)
    }
}
