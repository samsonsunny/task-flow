import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum AppNav: Hashable {
    case overdue
    case today
    case tomorrow
    case upcoming
    case later
    case completed
    case list(ReminderList.ID)
}

struct CountRow: View {
    let title: String
    let systemImage: String
    let count: Int?
    let labelColor: Color?

    init(title: String, systemImage: String, count: Int? = nil, labelColor: Color? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.count = count
        self.labelColor = labelColor
    }

    var body: some View {
        HStack {
            if let labelColor {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(labelColor)
            } else {
                Label(title, systemImage: systemImage)
            }
            Spacer()
            if let count, count > 0 {
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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    private var overdueCount: Int { ReminderSegmentLogic.count(for: .overdue, tasks: allTasks) }
    private var todayCount: Int { ReminderSegmentLogic.count(for: .today, tasks: allTasks) }
    private var tomorrowCount: Int { ReminderSegmentLogic.count(for: .tomorrow, tasks: allTasks) }
    private var upcomingCount: Int { ReminderSegmentLogic.count(for: .upcoming, tasks: allTasks) }
    private var laterCount: Int { ReminderSegmentLogic.count(for: .later, tasks: allTasks) }

    @ViewBuilder
    private func SidebarSmartSections() -> some View {
        Section {
            if overdueCount > 0 {
                NavigationLink(value: AppNav.overdue) {
                    CountRow(title: "Overdue", systemImage: "exclamationmark.circle.fill", count: overdueCount, labelColor: AppTheme.colors.error)
                }
            }

            NavigationLink(value: AppNav.today) {
                CountRow(title: "Today", systemImage: "calendar.circle.fill", count: todayCount)
            }

            NavigationLink(value: AppNav.tomorrow) {
                CountRow(title: "Tomorrow", systemImage: "sunrise.fill", count: tomorrowCount)
            }

            NavigationLink(value: AppNav.upcoming) {
                CountRow(title: "Upcoming", systemImage: "calendar.badge.clock", count: upcomingCount)
            }

            NavigationLink(value: AppNav.later) {
                CountRow(title: "Later", systemImage: "tray", count: laterCount)
            }

            NavigationLink(value: AppNav.completed) {
                Label("Completed", systemImage: "checkmark.circle.fill")
            }
        }
    }

    @State private var selection: AppNav? = .today
    @State private var isCreatingList = false
    @State private var newListName = ""

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                SidebarSmartSections()

                SidebarListsView(lists: allLists, tasks: allTasks)
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
            backfillSortOrdersIfNeeded(in: modelContext)
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

struct SidebarListsView: View {
    @Environment(\.modelContext) private var modelContext
    let lists: [ReminderList]
    let tasks: [TaskItem]
    @State private var dropTargetList: ReminderList?

    var body: some View {
        Section("Lists") {
            ForEach(lists, id: \.name) { list in
                let count = tasks.filter {
                    $0.reminderList?.persistentModelID == list.persistentModelID && $0.isCompleted != true
                }.count
                NavigationLink(value: AppNav.list(list.persistentModelID)) {
                    CountRow(title: list.name, systemImage: "list.bullet", count: count)
                }
                .onDrop(of: [.text], isTargeted: nil) { providers, _ in
                    handleDrop(providers: providers, to: list)
                    return true
                }
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider], to list: ReminderList) {
        guard let provider = providers.first else { return }
        provider.loadObject(ofClass: NSString.self) { [modelContext, list] string, error in
            guard let idString = string as? String else { return }
            DispatchQueue.main.async {
                let descriptor = FetchDescriptor<TaskItem>(
                    predicate: #Predicate { $0.taskId == idString }
                )
                guard let task = try? modelContext.fetch(descriptor).first else { return }
                guard task.reminderList?.persistentModelID != list.persistentModelID else { return }
                task.reminderList = list
                let all = try? modelContext.fetch(FetchDescriptor<TaskItem>())
                let listTasks = (all ?? []).filter {
                    $0.reminderList?.persistentModelID == list.persistentModelID &&
                    $0.persistentModelID != task.persistentModelID
                }
                let lastOrder = listTasks.compactMap { $0.sortOrder }.sorted().last
                task.sortOrder = midpoint(between: lastOrder, and: nil)
                try? modelContext.save()
            }
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
