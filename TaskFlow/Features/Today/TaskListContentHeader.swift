import SwiftUI

/// Compact heading that gives the task list context without competing with
/// the Work / Personal titles above it.
struct TaskListContentHeader: View {
    let title: String
    var showsDisclosure: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    label
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(title), change date")
            } else {
                label
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.xxs / 2)
        .padding(.bottom, AppSpacing.xxs)
    }

    private var label: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(AppFont.title)
                .foregroundStyle(AppTheme.colors.textPrimary)

            if showsDisclosure {
                Image(systemName: "chevron.down")
                    .font(AppFont.captionSemibold)
                    .foregroundStyle(AppTheme.colors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityAddTraits(.isHeader)
    }
}
