import SwiftUI
import SwiftData

enum AppNav: Hashable {
    case overdue
    case today
    case tomorrow
    case upcoming
    case later
    case completed
    case list(ReminderList.ID)
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderList.createdAt) private var allLists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var selection: AppNav? = .today
    @State private var isCreatingList = false
    @State private var newListName = ""

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    let overdueCount = ReminderSegmentLogic.count(for: .overdue, tasks: allTasks)
                    if overdueCount > 0 {
                        NavigationLink(value: AppNav.overdue) {
                            HStack {
                                Label("Overdue", systemImage: "exclamationmark.circle.fill")
                                    .foregroundStyle(AppTheme.colors.error)
                                Spacer()
                                Text("\(overdueCount)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.colors.error)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.colors.error.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    NavigationLink(value: AppNav.today) {
                        HStack {
                            Label("Today", systemImage: "calendar.circle.fill")
                            Spacer()
                            let count = ReminderSegmentLogic.count(for: .today, tasks: allTasks)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.colors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.colors.fillSubtle)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    NavigationLink(value: AppNav.tomorrow) {
                        HStack {
                            Label("Tomorrow", systemImage: "sunrise.fill")
                            Spacer()
                            let count = ReminderSegmentLogic.count(for: .tomorrow, tasks: allTasks)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.colors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.colors.fillSubtle)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    NavigationLink(value: AppNav.upcoming) {
                        HStack {
                            Label("Upcoming", systemImage: "calendar.badge.clock")
                            Spacer()
                            let count = ReminderSegmentLogic.count(for: .upcoming, tasks: allTasks)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.colors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.colors.fillSubtle)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    NavigationLink(value: AppNav.later) {
                        HStack {
                            Label("Later", systemImage: "tray")
                            Spacer()
                            let count = ReminderSegmentLogic.count(for: .later, tasks: allTasks)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.colors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.colors.fillSubtle)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    NavigationLink(value: AppNav.completed) {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                    }
                }

                Section("Lists") {
                    ForEach(allLists) { list in
                        NavigationLink(value: AppNav.list(list.persistentModelID)) {
                            HStack {
                                Label(list.name, systemImage: "list.bullet")
                                Spacer()
                                let count = allTasks.filter {
                                    $0.reminderList?.persistentModelID == list.persistentModelID
                                    && $0.isCompleted != true
                                }.count
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.colors.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.colors.fillSubtle)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.colors.appBackground)
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem {
                    Button {
                        newListName = ""
                        isCreatingList = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New List", isPresented: $isCreatingList) {
                TextField("List Name", text: $newListName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    let list = ReminderList(name: name)
                    modelContext.insert(list)
                }
            }
        } detail: {
            switch selection {
            case .overdue:
                ReminderSegmentDetailView(segment: .overdue)
                    .navigationTitle("Overdue")
                    .navigationBarTitleDisplayMode(.large)
            case .today:
                FilterDetailView(segment: .today)
            case .tomorrow:
                FilterDetailView(segment: .tomorrow)
            case .upcoming:
                FilterDetailView(segment: .upcoming)
            case .later:
                ReminderSegmentDetailView(segment: .later)
                    .navigationTitle("Later")
                    .navigationBarTitleDisplayMode(.large)
            case .completed:
                CompletedView()
                    .navigationTitle("Completed")
                    .navigationBarTitleDisplayMode(.large)
            case .list(let id):
                ListDetailView(listID: id)
            case nil:
                Text("Select a list")
                    .foregroundStyle(AppTheme.colors.textSecondary)
            }
        }
        .onAppear {
            migrateOrphanedTasks()
        }
    }

    private func migrateOrphanedTasks() {
        let key = "did_migrate_orphaned_tasks_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.reminderList == nil }
        )
        guard let orphans = try? modelContext.fetch(descriptor), !orphans.isEmpty else { return }

        let defaultName = ReminderDefaults.defaultListName
        let listDescriptor = FetchDescriptor<ReminderList>(
            predicate: #Predicate { $0.name == defaultName }
        )
        let defaultList: ReminderList
        if let existing = try? modelContext.fetch(listDescriptor).first {
            defaultList = existing
        } else {
            let list = ReminderList(name: ReminderDefaults.defaultListName)
            modelContext.insert(list)
            defaultList = list
        }

        for task in orphans {
            task.reminderList = defaultList
        }
        try? modelContext.save()
    }
}

struct SmartFilterTabbedView: View {
    let initialSegment: ReminderSegment
    @Binding var selectedTab: Int

    private let tabSegments: [ReminderSegment] = [.today, .tomorrow, .upcoming]

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(tabSegments.enumerated()), id: \.element) { index, segment in
                ReminderSegmentDetailView(segment: segment)
                    .tabItem {
                        Label(segment.tabTitle, systemImage: segment.iconName)
                    }
                    .tag(index)
            }
        }
        .onAppear {
            selectedTab = tabSegments.firstIndex(of: initialSegment) ?? 0
        }
    }
}

struct FilterDetailView: View {
    let segment: ReminderSegment
    @State private var selectedTab: Int

    init(segment: ReminderSegment) {
        self.segment = segment
        _selectedTab = State(initialValue: ReminderSegment.allCases.firstIndex(of: segment) ?? 0)
    }

    var body: some View {
        SmartFilterTabbedView(initialSegment: segment, selectedTab: $selectedTab)
            .navigationTitle(ReminderSegment.allCases[selectedTab].title)
            .navigationBarTitleDisplayMode(.large)
    }
}

#Preview("Empty State") {
    let container = TaskPreviewData.container()
    TaskPreviewData.ensureDefaultListExists(in: container.mainContext)
    return ContentView()
        .modelContainer(container)
        .environment(AppState())
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return ContentView()
        .modelContainer(container)
        .environment(AppState())
}
