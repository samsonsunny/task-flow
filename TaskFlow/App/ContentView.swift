//
//  ContentView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//

// ==========================================
// MARK: - Content View
// File: App/ContentView.swift
// ==========================================

import SwiftUI
import SwiftData

struct ContentView: View {
    private let launchArguments = ProcessInfo.processInfo.arguments
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = ReminderRootTab.today
    @State private var todayPath: [ReminderRoute] = []
    @State private var tomorrowPath: [ReminderRoute] = []
    @State private var upcomingPath: [ReminderRoute] = []

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                reminderTab(for: .today, path: $todayPath)
                    .tag(ReminderRootTab.today)

                reminderTab(for: .tomorrow, path: $tomorrowPath)
                    .tag(ReminderRootTab.tomorrow)

                reminderTab(for: .upcoming, path: $upcomingPath)
                    .tag(ReminderRootTab.upcoming)
            }
            .onAppear {
                if launchArguments.contains("UITEST_OPEN_UPCOMING") {
                    selectedTab = .upcoming
                }
                migrateOrphanedTasks()
            }

            SidebarContainer()
        }
        .onChange(of: appState.pendingNavigation) { _, route in
            guard let route else { return }
            switch selectedTab {
            case .today: todayPath.append(route)
            case .tomorrow: tomorrowPath.append(route)
            case .upcoming: upcomingPath.append(route)
            }
            appState.pendingNavigation = nil
        }
    }

    private func reminderTab(for segment: ReminderSegment, path: Binding<[ReminderRoute]>) -> some View {
        NavigationStack(path: path) {
            ReminderSegmentDetailView(segment: segment)
                .navigationDestination(for: ReminderRoute.self) { destination in
                    switch destination {
                    case .segment(let segment):
                        ReminderSegmentDetailView(segment: segment)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                appState.isSidebarOpen.toggle()
                            }
                        } label: {
                            Image(systemName: appState.isSidebarOpen ? "xmark" : "sidebar.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(AppTheme.colors.textSecondary)
                        }
                        .accessibilityIdentifier("sidebar-toggle-button")
                    }
                }
        }
        .tabItem {
            Label(segment.tabTitle, systemImage: segment.iconName)
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

private enum ReminderRootTab: Hashable {
    case today
    case tomorrow
    case upcoming
}

enum ReminderRoute: Hashable {
    case segment(ReminderSegment)
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
