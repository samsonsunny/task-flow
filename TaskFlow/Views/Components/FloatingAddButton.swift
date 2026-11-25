import SwiftUI
import SwiftData

struct NewTaskSheetConfig: Identifiable {
    let id = UUID()
    let initialDate: Date?
    let initialListID: ReminderList.ID?
}

/// The shared native create affordance. It belongs in a navigation toolbar, matching
/// the system "+" pattern used by Reminders and other iOS productivity apps.
struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Image(systemName: "plus")
                .font(AppFont.body.weight(.semibold))
        }
        .frame(minWidth: AppSpacing.minimumTapTarget, minHeight: AppSpacing.minimumTapTarget)
        .accessibilityLabel("New Task")
        .accessibilityIdentifier("floating-add-button")
    }
}
