import SwiftUI
import SwiftData

/// The time-based screens reachable as pushed destinations. No longer tab identifiers —
/// the tab bar is gone, and the segment picker is gone with it.
//enum HomeSegment: String, CaseIterable, Identifiable, Hashable {
//    case today
//    case tomorrow
//    case upcoming
//
//    var id: String { rawValue }
//
//    var title: String {
//        switch self {
//        case .today: return "Today"
//        case .tomorrow: return "Tomorrow"
//        case .upcoming: return "Upcoming"
//        }
//    }
//}
//
///// The single stack of Home destinations. Replaces the split-view sidebar selection:
///// Home owns the only navigation state in the app, so every destination is pushed onto
///// one path.
//enum HomeDestination: Hashable {
//    case overdue
//    case segment(HomeSegment)
//}

/// The two-segment area switcher, rendered as a native segmented control in the title slot.
///
/// `.principal` is the only toolbar placement wide enough to hold a segmented control — a
/// custom control in the leading slot gets width-clipped to the point of hiding its own
/// labels. Native rather than custom pills for two more reasons: it is the platform-standard
/// affordance for "pick one of a few fixed modes", and it inherits pointer, keyboard, and
/// VoiceOver behaviour without reimplementing them. The cost of the title slot is the large
/// title, so Home uses the compact inline display mode and the switcher stays visible at all
/// scroll offsets.
//struct AreaSwitcher: View {
//    let areas: [ReminderListGroup]
//    let selectedID: ReminderListGroup.ID?
//    let onSelect: (ReminderListGroup) -> Void
//
//    var body: some View {
//        Picker("Area", selection: selection) {
//            ForEach(areas) { area in
//                Text(area.name).tag(area.persistentModelID)
//            }
//        }
//        .pickerStyle(.segmented)
//        .labelsHidden()
//        .disabled(areas.count < 2)
//        .accessibilityIdentifier("home-area-switcher")
//    }
//
//    private var selection: Binding<ReminderListGroup.ID?> {
//        Binding(
//            get: { selectedID ?? areas.first?.persistentModelID },
//            set: { newValue in
//                guard let newValue,
//                      let match = areas.first(where: { $0.persistentModelID == newValue }),
//                      newValue != selectedID
//                else { return }
//                onSelect(match)
//            }
//        )
//    }
//}

//struct HomeView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Environment(AppState.self) private var appState
//
//    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]
//    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
//    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
//
//    @State private var viewModel: HomeViewModel?
//    @State private var editingTask: TaskItem?
//    @State private var path: [HomeDestination] = []
//
//    var body: some View {
//        // The stack lives here, not in `MainTabView`: `path` is only honoured by the
//        // `NavigationStack` it is bound to, so splitting them silently drops every push.
//        NavigationStack(path: $path) {
//            listContent
//                .navigationTitle("My Tasks")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .principal) {
//                        areaSwitcher
//                    }
//                }
//                .navigationDestination(for: HomeDestination.self) { destination in
//                    // The former `MainTabView.destinationStack` supplied these titles. The
//                    // split view is gone, so each destination has to title itself.
//                    destinationView(for: destination)
//                        .navigationTitle(title(for: destination))
//                        .navigationBarTitleDisplayMode(.inline)
//                }
//                // Pushed, not presented as a sheet: the editor's close and save buttons live in
//                // a navigation-bar toolbar, so it needs a real `NavigationStack` to render them.
//                // `embedInNavigationStack: false` hands that job to Home's stack — the same
//                // arrangement `TimelineView` and `DetailView` use.
//                .navigationDestination(item: $editingTask) { task in
//                    ReminderEditorView(task: task, embedInNavigationStack: false)
//                }
//        }
//        .onAppear(perform: bootstrap)
//        .onChange(of: groups) { _, _ in refresh() }
//        .onChange(of: lists) { _, _ in refresh() }
//        .onChange(of: allTasks) { _, _ in refresh() }
//        .onChange(of: appState.selectedAreaID) { _, _ in refresh() }
//    }
//
//    // MARK: - Content
//
//    private var listContent: some View {
//        VStack(spacing: 0) {
//            scopeSwitcher
//            taskList
//        }
//    }
//
//    /// The Work/Personal segmented control, living in the navigation bar's title slot.
//    private var areaSwitcher: some View {
//        AreaSwitcher(
//            areas: appState.areas,
//            selectedID: appState.selectedAreaID,
//            onSelect: { area in
//                appState.selectArea(area)
//                viewModel?.selectArea(area)
//                refresh()
//            }
//        )
//    }
//
//    /// The Planned / Unplanned switch. It replaces the former CTA-and-pushed-page: the undated
//    /// backlog is one tap away in the same list rather than a separate screen. The Unplanned
//    /// label carries its count so the backlog stays visible while the Planned half is showing.
//    private var scopeSwitcher: some View {
//        Picker("Scope", selection: scopeBinding) {
//            Text(HomeScope.planned.title).tag(HomeScope.planned)
//            Text(unplannedSegmentLabel).tag(HomeScope.unplanned)
//        }
//        .pickerStyle(.segmented)
//        .labelsHidden()
//        .padding(.horizontal, 16)
//        .padding(.top, 8)
//        .accessibilityIdentifier("home-scope-switcher")
//    }
//
//    private var scopeBinding: Binding<HomeScope> {
//        Binding(
//            get: { viewModel?.scope ?? .planned },
//            set: { viewModel?.selectScope($0) }
//        )
//    }
//
//    private var unplannedSegmentLabel: String {
//        let count = viewModel?.undatedTasks.count ?? 0
//        return count > 0 ? "Unplanned \(count)" : HomeScope.unplanned.title
//    }
//
//    /// One list, two halves. Planned shows the due-date buckets (overdue, then today, then
//    /// future); Unplanned shows the same area's undated work, newest first. Both reuse the same
//    /// rows and mutations — only the source pool changes.
//    private var taskList: some View {
//        List {
//            switch viewModel?.scope ?? .planned {
//            case .planned:
//                plannedContent
//            case .unplanned:
//                unplannedContent
//            }
//        }
//        .listStyle(.plain)
//        .scrollEdgeEffectStyle(.soft, for: .bottom)
//        .refreshable {
//            refresh()
//        }
//    }
//
//    private var plannedContent: some View {
//        // Due-date buckets, overdue first, then today, then future work. The ViewModel always
//        // includes today, so an empty one gets a nudge row instead of vanishing and leaving the
//        // schedule looking blank. Overdue and upcoming only appear when they carry work.
//        ForEach(viewModel?.datedSections ?? []) { section in
//            Section {
//                if section.tasks.isEmpty {
//                    todayNudge
//                } else {
//                    ForEach(section.tasks) { task in
//                        taskRow(task, showsDueDate: true)
//                    }
//                }
//            } header: {
//                sectionHeader(section)
//            }
//        }
//    }
//
//    /// Placeholder shown under the Today header when nothing is due — keeps the Planned half
//    /// anchored and doubles as a gentle prompt to plan the day.
//    private var todayNudge: some View {
//        HStack(spacing: 10) {
//            Image(systemName: "sun.max")
//                .font(.system(size: 16))
//                .foregroundStyle(AppTheme.colors.textTertiary)
//
//            VStack(alignment: .leading, spacing: 2) {
//                Text("Nothing due today")
//                    .font(.subheadline.weight(.medium))
//                    .foregroundStyle(AppTheme.colors.textSecondary)
//
//                Text("A clear day. Add something whenever you're ready.")
//                    .font(.caption)
//                    .foregroundStyle(AppTheme.colors.textTertiary)
//            }
//        }
//        .padding(.vertical, 8)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .listRowSeparator(.hidden)
//        .listRowBackground(Color.clear)
//        .accessibilityElement(children: .combine)
//    }
//
//    @ViewBuilder
//    private var unplannedContent: some View {
//        if let viewModel, viewModel.undatedTasks.isEmpty {
//            emptyState(
//                title: "Nothing unscheduled",
//                message: "Tasks you add without a due date will collect here."
//            )
//        } else {
//            ForEach(viewModel?.undatedTasks ?? []) { task in
//                taskRow(task, showsDueDate: false)
//            }
//        }
//    }
//
//    private func taskRow(_ task: TaskItem, showsDueDate: Bool) -> some View {
//        TaskRowView(
//            task: task,
//            // Only incomplete tasks reach this list, so the row always draws as pending.
//            isCompletedVisualState: task.isCompleted ?? false,
//            onToggleCompletion: { viewModel?.toggleCompletion(for: task) },
//            onDelete: { viewModel?.delete(task) },
//            onTap: { editingTask = task },
//            showsDueDate: showsDueDate,
//            showsListName: true
//        )
//        .listRowSeparator(.hidden)
//        .listRowBackground(Color.clear)
//    }
//
//    private func emptyState(title: String, message: String) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(title)
//                .font(.headline)
//                .foregroundStyle(AppTheme.colors.textSecondary)
//
//            Text(message)
//                .font(.caption)
//                .foregroundStyle(AppTheme.colors.textTertiary)
//        }
//        .padding(.vertical, 24)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .listRowSeparator(.hidden)
//        .listRowBackground(Color.clear)
//        .accessibilityElement(children: .combine)
//    }
//
//    private func sectionHeader(_ section: HomeTaskSection) -> some View {
//        HStack(spacing: 6) {
//            Image(systemName: section.iconName)
//                .font(.caption)
//                .foregroundStyle(AppTheme.colors.textSecondary)
//
//            Text(section.title)
//                .font(.subheadline.weight(.semibold))
//                .foregroundStyle(AppTheme.colors.textSecondary)
//
//            Text("\(section.tasks.count)")
//                .font(.caption)
//                .foregroundStyle(AppTheme.colors.textTertiary)
//
//            Spacer()
//        }
//        .textCase(nil)
//        .padding(.vertical, 4)
//    }
//
//    // MARK: - Destinations
//
//    @ViewBuilder
//    private func destinationView(for destination: HomeDestination) -> some View {
//        switch destination {
//        case .overdue:
//            ReminderSegmentDetailView(segment: .overdue)
//        case .segment(.today):
//            TodayTabView()
//        case .segment(.tomorrow):
//            TomorrowView()
//        case .segment(.upcoming):
//            UpcomingView()
//        }
//    }
//
//    private func title(for destination: HomeDestination) -> String {
//        switch destination {
//        case .overdue:
//            return ReminderSegment.overdue.title
//        case .segment(let segment):
//            return segment.title
//        }
//    }
//
//    // MARK: - Lifecycle
//
//    private func bootstrap() {
//        appState.updateAreas(groups)
//        if viewModel == nil {
//            viewModel = HomeViewModel(modelContext: modelContext)
//        }
//        refresh()
//    }
//
//    private func refresh() {
//        appState.updateAreas(groups)
//        guard let viewModel else { return }
//        viewModel.update(
//            groups: groups,
//            lists: lists,
//            allTasks: allTasks,
//            areaID: appState.selectedAreaID
//        )
//    }
//}

//#Preview("Both Areas") {
//    let container = TaskPreviewData.container()
//    TaskPreviewData.seedBothAreasFixture(into: container)
//    return HomeView()
//        .modelContainer(container)
//        .environment(AppState())
//}
//
//#Preview("Empty") {
//    let container = TaskPreviewData.container()
//    TaskPreviewData.seedDefaultAreas(in: container.mainContext)
//    return HomeView()
//        .modelContainer(container)
//        .environment(AppState())
//}
