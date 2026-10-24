import SwiftUI

struct DateChip: View {
    let date: Date
    let width: CGFloat
    let height: CGFloat
    let isSelected: Bool
    let onSelect: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        let isToday = calendar.isDateInToday(date)
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let dayString = isToday ? "Today" : dayFormatter.string(from: date)
        let numString = dateFormatter.string(from: date)

        return Button(action: onSelect) {
            VStack(spacing: 0) {
                Text(dayString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? AppTheme.colors.textOnTint : AppTheme.colors.textSecondary)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 3) {
                    Text(numString)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.colors.textOnTint : AppTheme.colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if isToday && !isSelected {
                        Circle()
                            .fill(AppTheme.colors.tint)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .padding(.vertical, 8)
            .frame(width: width)
            .frame(minHeight: height)
            .background(isSelected ? AppTheme.colors.tint : (isToday ? Color.clear : AppTheme.colors.surfaceElevated.opacity(0.6)))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppTheme.colors.tint, lineWidth: isToday && !isSelected ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
