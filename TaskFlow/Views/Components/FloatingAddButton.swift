import SwiftUI
import SwiftData

struct NewTaskSheetConfig: Identifiable {
    let id = UUID()
    let initialDate: Date?
    let initialListID: ReminderList.ID?
}

/// The Android-style create affordance pinned to the bottom-right of a task screen.
struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppTheme.colors.textOnTint)
                .frame(width: 56, height: 56)
                .background(AppTheme.colors.tint, in: Circle())
                .shadow(color: .black.opacity(0.22), radius: 3, x: 0, y: 2)
                .shadow(color: AppTheme.colors.tint.opacity(0.35), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("New Task")
        .accessibilityIdentifier("floating-add-button")
        .padding(.trailing, 20)
        .padding(.bottom, 36)
    }
}
