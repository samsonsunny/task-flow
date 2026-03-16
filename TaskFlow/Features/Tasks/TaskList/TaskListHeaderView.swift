import SwiftUI

struct TaskListHeaderView: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.colors.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.textPrimary.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

