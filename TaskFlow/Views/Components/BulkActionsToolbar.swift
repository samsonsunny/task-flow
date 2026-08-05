import SwiftUI

struct BulkActionsToolbar: View {
    let selectedCount: Int
    let onDelete: () -> Void
    let onRescheduleToday: () -> Void
    let onRescheduleTomorrow: () -> Void
    let onRescheduleThisWeekend: () -> Void
    let onRescheduleNextWeek: () -> Void
    let onRescheduleNextMonth: () -> Void
    let onRescheduleCustom: () -> Void
    let onRescheduleNone: () -> Void
    let onMoveToList: (ReminderList) -> Void
    let listSections: [ListSection]
    let onSetPriority: (ReminderPriority) -> Void
    let onComplete: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 0) {
                Menu {
                    Button("Today", action: onRescheduleToday)
                    Button("Tomorrow", action: onRescheduleTomorrow)
                    Button("This Weekend", action: onRescheduleThisWeekend)
                    Button("Next Week", action: onRescheduleNextWeek)
                    Button("Next Month", action: onRescheduleNextMonth)
                    Divider()
                    Button("Pick a Date…", action: onRescheduleCustom)
                    Button("None", action: onRescheduleNone)
                } label: {
                    toolbarButtonLabel(icon: "calendar", label: "Date")
                }

                Spacer()

                Menu {
                    ForEach(listSections) { section in
                        if let title = section.title, !title.isEmpty {
                            Section(title) {
                                ForEach(section.lists) { list in
                                    Button(list.name) {
                                        onMoveToList(list)
                                    }
                                }
                            }
                        } else {
                            ForEach(section.lists) { list in
                                Button(list.name) {
                                    onMoveToList(list)
                                }
                            }
                        }
                    }
                } label: {
                    toolbarButtonLabel(icon: "folder", label: "Move")
                }

                Spacer()

                Menu {
                    Button("Low") { onSetPriority(.low) }
                    Button("Medium") { onSetPriority(.medium) }
                    Button("High") { onSetPriority(.high) }
                    Divider()
                    Button("None") { onSetPriority(.none) }
                } label: {
                    toolbarButtonLabel(icon: "tag", label: "Tag")
                }

                Spacer()

                Button(action: onComplete) {
                    toolbarButtonLabel(icon: "checkmark.circle", label: "Complete")
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onDelete) {
                    toolbarButtonLabel(icon: "trash", label: "Delete", isDestructive: true)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            HStack {
                Spacer()

                Text("\(selectedCount) selected")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.colors.textSecondary)

                Spacer()
            }
            .padding(.bottom, 8)
        }
        .background(AppTheme.colors.surface)
    }

    private func toolbarButtonLabel(icon: String, label: String, isDestructive: Bool = false) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(isDestructive ? AppTheme.colors.error : AppTheme.colors.primaryAction)

            Text(label)
                .font(.caption2)
                .foregroundStyle(isDestructive ? AppTheme.colors.error : AppTheme.colors.textSecondary)
        }
        .frame(width: 56)
    }
}
