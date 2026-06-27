import SwiftUI

struct MoreView: View {
    @AppStorage(DailyReminderKeys.enabled) private var isEnabled = false
    @AppStorage(DailyReminderKeys.hour) private var hour = 7
    @AppStorage(DailyReminderKeys.minute) private var minute = 0

    @Environment(\.dismiss) private var dismiss

    private let notif = NotificationService.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Daily Morning Reminder", isOn: Binding(
                        get: { isEnabled },
                        set: { newValue in
                            if newValue {
                                enableReminder()
                            } else {
                                disableReminder()
                            }
                        }
                    ))

                    if isEnabled {
                        DatePicker(
                            "Time",
                            selection: Binding(
                                get: { calendarDate(from: hour, minute: minute) },
                                set: { newDate in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                    hour = components.hour ?? 7
                                    minute = components.minute ?? 0
                                    notif.cancelDailyReminder()
                                    notif.scheduleDailyReminder(hour: hour, minute: minute)
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if isEnabled {
                        Text("A daily notification will remind you to check your tasks.")
                    }
                }
                Section {
                    NavigationLink {
                        CompletedView()
                            .navigationTitle("Completed")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("Recently Completed", systemImage: "checkmark.circle")
                    }
                } header: {
                    Text("Recently Completed")
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func enableReminder() {
        Task {
            let granted = await notif.requestAuthorizationIfNeeded()
            if granted {
                isEnabled = true
                notif.scheduleDailyReminder(hour: hour, minute: minute)
            } else {
                isEnabled = false
            }
        }
    }

    private func disableReminder() {
        isEnabled = false
        notif.cancelDailyReminder()
    }

    private func calendarDate(from hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}
