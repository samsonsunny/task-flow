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
        .padding(.horizontal, 20)
        .padding(.top, 2)
        .padding(.bottom, 4)
    }

    private var label: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.colors.textPrimary)

            if showsDisclosure {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityAddTraits(.isHeader)
    }
}
