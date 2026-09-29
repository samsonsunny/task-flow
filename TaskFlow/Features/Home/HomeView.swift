import SwiftUI
import SwiftData

/// The time-based screens reachable as pushed destinations. No longer tab identifiers —
/// the tab bar is gone, and the segment picker is gone with it.
enum HomeSegment: String, CaseIterable, Identifiable, Hashable {
    case today
    case tomorrow
    case upcoming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .upcoming: return "Upcoming"
        }
    }
}

/// The single stack of Home destinations. Replaces the split-view sidebar selection:
/// Home owns the only navigation state in the app, so every destination is pushed onto
/// one path.
enum HomeDestination: Hashable {
    case overdue
    case segment(HomeSegment)
}

/// The two-segment area switcher, rendered as a native segmented control in the title slot.
///
/// `.principal` is the only toolbar placement wide enough to hold a segmented control — a
/// custom control in the leading slot gets width-clipped to the point of hiding its own
/// labels. Native rather than custom pills for two more reasons: it is the platform-standard
/// affordance for "pick one of a few fixed modes", and it inherits pointer, keyboard, and
/// VoiceOver behaviour without reimplementing them. The cost of the title slot is the large
/// title, so Home uses the compact inline display mode and the switcher stays visible at all
/// scroll offsets.
struct AreaSwitcher: View {
    let areas: [ReminderListGroup]
    let selectedID: ReminderListGroup.ID?
    let onSelect: (ReminderListGroup) -> Void

    var body: some View {
        Picker("Area", selection: selection) {
            ForEach(areas) { area in
                Text(area.name).tag(area.persistentModelID)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .disabled(areas.count < 2)
        .accessibilityIdentifier("home-area-switcher")
    }

    private var selection: Binding<ReminderListGroup.ID?> {
        Binding(
            get: { selectedID ?? areas.first?.persistentModelID },
            set: { newValue in
                guard let newValue,
                      let match = areas.first(where: { $0.persistentModelID == newValue }),
                      newValue != selectedID
                else { return }
                onSelect(match)
            }
        )
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var viewModel: HomeViewModel?
    @State private var captureViewModel: CaptureBarViewModel?
    @State private var editingTask: TaskItem?
    @State private var path: [HomeDestination] = []

    var body: some View {
        // The stack lives here, not in `MainTabView`: `path` is only honoured by the
        // `NavigationStack` it is bound to, so splitting them silently drops every push.
        NavigationStack(path: $path) {
            listContent
                .navigationTitle("My Tasks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        areaSwitcher
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    captureBar
                }
                .navigationDestination(for: HomeDestination.self) { destination in
                    // The former `MainTabView.destinationStack` supplied these titles. The
                    // split view is gone, so each destination has to title itself.
                    destinationView(for: destination)
                        .navigationTitle(title(for: destination))
                        .navigationBarTitleDisplayMode(.inline)
                }
                // Pushed, not presented as a sheet: the editor's close and save buttons live in
                // a navigation-bar toolbar, so it needs a real `NavigationStack` to render them.
                // `embedInNavigationStack: false` hands that job to Home's stack — the same
                // arrangement `TimelineView` and `DetailView` use.
                .navigationDestination(item: $editingTask) { task in
                    ReminderEditorView(task: task, embedInNavigationStack: false)
                }
        }
        .onAppear(perform: bootstrap)
        .onChange(of: groups) { _, _ in refresh() }
        .onChange(of: lists) { _, _ in refresh() }
        .onChange(of: allTasks) { _, _ in refresh() }
        .onChange(of: appState.selectedAreaID) { _, _ in refresh() }
    }

    // MARK: - Content

    private var listContent: some View {
        VStack(spacing: 0) {
            filterBar
            taskList
        }
    }

    /// The Work/Personal segmented control, living in the navigation bar's title slot.
    private var areaSwitcher: some View {
        AreaSwitcher(
            areas: appState.areas,
            selectedID: appState.selectedAreaID,
            onSelect: { area in
                appState.selectArea(area)
                viewModel?.selectArea(area)
                refresh()
            }
        )
    }

    /// The one-filter-at-a-time chip row above the task list. "Recents" is the default state —
    /// every incomplete task in the area, newest first. The date chips resolve to the same
    /// buckets as the pushed time views, so membership and counts never disagree.
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HomeFilter.allCases) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier("home-filter-bar")
    }

    private func filterChip(_ filter: HomeFilter) -> some View {
        let isSelected = viewModel?.filter == filter
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                viewModel?.selectFilter(filter)
            }
        } label: {
            Text(filter.title)
                .font(.subheadline.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? AppTheme.colors.textOnPrimaryAction : AppTheme.colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? AppTheme.colors.primaryAction : AppTheme.colors.fillSubtle))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home-filter-\(filter.rawValue)")
        .accessibilityLabel(filter.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var taskList: some View {
        List {
            if viewModel?.tasks.isEmpty == true, let segment = viewModel?.filter.reminderSegment {
                // Only the date chips get an empty state: a blank Recents list is the app's
                // established "no tasks in this area yet" cue, so it is left as-is.
                emptyState(segment: segment)
            } else {
                // One flat list of the selected area's tasks under the active filter. Nothing
                // is grouped: the list name rides on each row's secondary line next to the
                // date, so the chosen ordering is the only one the user has to read.
                ForEach(viewModel?.tasks ?? []) { task in
                    TaskRowView(
                        task: task,
                        // Only incomplete tasks reach this list, so the row always draws as
                        // pending. Passed explicitly so that stays true if the filter ever changes.
                        isCompletedVisualState: task.isCompleted ?? false,
                        onToggleCompletion: { viewModel?.toggleCompletion(for: task) },
                        onDelete: { viewModel?.delete(task) },
                        onTap: { editingTask = task },
                        showsDueDate: true,
                        showsListName: true
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .contentMargins(.bottom, AppTheme.captureBarClearance, for: .scrollContent)
        .refreshable {
            captureViewModel?.refreshNow()
            refresh()
        }
    }

    private func emptyState(segment: ReminderSegment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(segment.emptyTitle)
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textSecondary)

            Text(segment.emptyMessage)
                .font(.caption)
                .foregroundStyle(AppTheme.colors.textTertiary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destinationView(for destination: HomeDestination) -> some View {
        switch destination {
        case .overdue:
            ReminderSegmentDetailView(segment: .overdue)
        case .segment(.today):
            TodayTabView()
        case .segment(.tomorrow):
            TomorrowView()
        case .segment(.upcoming):
            UpcomingView()
        }
    }

    private func title(for destination: HomeDestination) -> String {
        switch destination {
        case .overdue:
            return ReminderSegment.overdue.title
        case .segment(let segment):
            return segment.title
        }
    }

    // MARK: - Capture

    private var captureBar: some View {
        CaptureBar(
            viewModel: captureViewModel ?? CaptureBarViewModel(modelContext: modelContext),
            onCommit: { text, notes in
                // Capture resolves against the selected area, not whichever screen the user
                // happens to be looking at — a Personal user never lands in Work.
                guard let areaID = appState.selectedAreaID ?? appState.areas.first?.persistentModelID else { return }
                captureViewModel?.commit(
                    text: text,
                    notes: notes,
                    target: .area(areaID),
                    selectedAreaID: areaID,
                    overrideDate: appState.pendingCaptureDate
                )
                appState.pendingCaptureDate = nil
                captureViewModel?.isFocusingCapture = false
                refresh()
            },
            autofocusRequest: captureViewModel?.isFocusingCapture ?? false
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - Lifecycle

    private func bootstrap() {
        appState.updateAreas(groups)
        if viewModel == nil {
            viewModel = HomeViewModel(modelContext: modelContext)
        }
        if captureViewModel == nil {
            captureViewModel = CaptureBarViewModel(modelContext: modelContext)
        }
        refresh()
        if !appState.hasAutoFocusedOnce {
            captureViewModel?.isFocusingCapture = true
            appState.markAutoFocusedOnce()
        }
    }

    private func refresh() {
        appState.updateAreas(groups)
        guard let viewModel else { return }
        viewModel.update(
            groups: groups,
            lists: lists,
            allTasks: allTasks,
            areaID: appState.selectedAreaID
        )
    }
}

#Preview("Both Areas") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedBothAreasFixture(into: container)
    return HomeView()
        .modelContainer(container)
        .environment(AppState())
}

#Preview("Empty") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedDefaultAreas(in: container.mainContext)
    return HomeView()
        .modelContainer(container)
        .environment(AppState())
}
