import SwiftUI

struct SelectionCircle: View {
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 20

    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? AppColors.primaryAction : AppColors.border, lineWidth: 1.5)
                .background(
                    Circle()
                        .fill(isSelected ? AppColors.primaryAction : Color.clear)
                )
                .frame(width: diameter, height: diameter)
                .animation(.easeInOut(duration: 0.18), value: isSelected)

            Image(systemName: "checkmark")
                .font(AppFont.caption2Semibold)
                .foregroundStyle(AppColors.textOnPrimaryAction)
                .opacity(isSelected ? 1 : 0)
                .scaleEffect(isSelected ? 1.0 : 0.85)
                .animation(.easeInOut(duration: 0.14), value: isSelected)
        }
        .frame(width: AppSpacing.minimumTapTarget, height: AppSpacing.minimumTapTarget)
        .contentShape(Rectangle())
    }
}
