import SwiftUI
import SwiftData

struct MoreView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]

    @State private var viewModel: MoreViewModel?
    @State private var isCreatingProject = false
    @State private var renamingProject: ReminderListGroup?
    @State private var deletingProject: ReminderListGroup?

    @AppStorage(DailyReminderKeys.enabled) private var isEnabled = false
    @AppStorage(DailyReminderKeys.hour) private var hour = 7
    @AppStorage(DailyReminderKeys.minute) private var minute = 0
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system.rawValue

    private let notif = NotificationService.shared
    private let appStoreURL = URL(string: "https://apps.apple.com/us/app/wednesday/id1455779789")!
    private let reviewURL = URL(string: "https://apps.apple.com/us/app/wednesday/id1455779789?action=write-review")!
    private let feedbackURL = URL(string: "mailto:samsonsunny@outlook.com?subject=Wednesday%20Calendar%20Feedback")!

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(groups) { group in
                        NavigationLink {
                            ListsView(groupID: group.persistentModelID)
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            Label(
                                areaDisplayName(group.name),
                                systemImage: projectIcon(for: group)
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if viewModel?.canModify(group) ?? false {
                                Button {
                                    deletingProject = group
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(AppTheme.colors.error)

                                Button {
                                    renamingProject = group
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(AppTheme.colors.tint)
                            }
                        }
                    }

                    Button {
                        Haptics.impact(.light)
                        isCreatingProject = true
                    } label: {
                        Label("New Project", systemImage: "plus")
                    }
                } header: {
                    Text("Projects")
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
                    Text("Activity")
                }

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
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                } header: {
                    Text("Display")
                }

                Section {
                    LabeledContent {
                        Text(iCloudStatus)
                    } label: {
                        Label("iCloud Sync", systemImage: "icloud")
                    }
                } header: {
                    Text("iCloud")
                } footer: {
                    Text(iCloudFooter)
                }

                Section {
                    LabeledContent("Version", value: versionText)

                    Link(destination: feedbackURL) {
                        Label("Send Feedback", systemImage: "envelope")
                    }

                    Link(destination: reviewURL) {
                        Label("Rate Wednesday Calendar", systemImage: "star")
                    }

                    ShareLink(item: appStoreURL) {
                        Label("Share Wednesday Calendar", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("More")
        }
        .onAppear(perform: bootstrap)
        .onChange(of: groups) { _, _ in refresh() }
        .sheet(isPresented: $isCreatingProject) {
            ProjectNameSheet { name in
                let created = viewModel?.createProject(named: name) != nil
                refresh()
                return created
            }
        }
        .sheet(item: $renamingProject) { project in
            ProjectNameSheet(
                title: "Rename Project",
                confirmTitle: "Rename",
                footerText: "Choose a new name for this project.",
                initialName: project.name
            ) { name in
                let renamed = viewModel?.renameProject(project, to: name) ?? false
                refresh()
                return renamed
            }
        }
        .overlay {
            if let deletingProject {
                ConfirmationOverlay(
                    title: "Delete \(deletingProject.name)?",
                    message: "Its lists and all their tasks will be deleted. This cannot be undone.",
                    confirmTitle: "Delete",
                    onConfirm: { commitDeleteProject() },
                    onCancel: { self.deletingProject = nil }
                )
            }
        }
        .animation(.easeInOut(duration: 0.18), value: deletingProject != nil)
    }

    private func commitDeleteProject() {
        guard let deletingProject else { return }
        viewModel?.deleteProject(deletingProject)
        self.deletingProject = nil
        refresh()
    }

    private func projectIcon(for group: ReminderListGroup) -> String {
        switch group.name {
        case AreaNames.work: return "briefcase"
        case AreaNames.personal: return "house"
        default: return "folder"
        }
    }

    private func bootstrap() {
        if viewModel == nil {
            viewModel = MoreViewModel(modelContext: modelContext)
        }
        refresh()
    }

    private func refresh() {
        viewModel?.update(groups: groups)
    }

    private var iCloudStatus: String {
        FileManager.default.ubiquityIdentityToken == nil ? "Off" : "On"
    }

    private var iCloudFooter: String {
        iCloudStatus == "On"
            ? "Your tasks sync automatically across devices signed in to the same Apple ID."
            : "Sign in to iCloud in Settings to sync your tasks across devices."
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
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

#Preview {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedDefaultAreas(in: container.mainContext)
    return MoreView()
        .modelContainer(container)
        .environment(AppState())
}
