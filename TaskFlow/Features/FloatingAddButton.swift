import SwiftUI

struct ReminderFloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.colors.textOnPrimaryAction)
                .frame(width: 58, height: 58)
                .background(
                    Circle()
                        .fill(AppTheme.colors.primaryAction)
                )
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 10)
        .accessibilityIdentifier("reminder-create-button")
        .accessibilityLabel("New Reminder")
    }
}
