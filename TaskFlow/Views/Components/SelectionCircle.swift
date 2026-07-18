import SwiftUI

struct SelectionCircle: View {
    let isSelected: Bool
    var body: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? AppTheme.colors.primaryAction : AppTheme.colors.border, lineWidth: 1.5)
                .background(
                    Circle()
                        .fill(isSelected ? AppTheme.colors.primaryAction : Color.clear)
                )
                .frame(width: 20, height: 20)
                .animation(.easeInOut(duration: 0.18), value: isSelected)

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.colors.textOnPrimaryAction)
                .opacity(isSelected ? 1 : 0)
                .scaleEffect(isSelected ? 1.0 : 0.85)
                .animation(.easeInOut(duration: 0.14), value: isSelected)
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
}
