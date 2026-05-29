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
    @State private var selectedTab = ReminderRootTab.today
    @State private var todayPath: [ReminderRoute] = []
    @State private var tomorrowPath: [ReminderRoute] = []
    @State private var upcomingPath: [ReminderRoute] = []
    @State private var laterPath: [ReminderRoute] = []

    var body: some View {
        TabView(selection: $selectedTab) {
            reminderTab(for: .today, path: $todayPath)
                .tag(ReminderRootTab.today)

            reminderTab(for: .tomorrow, path: $tomorrowPath)
                .tag(ReminderRootTab.tomorrow)

            reminderTab(for: .upcoming, path: $upcomingPath)
                .tag(ReminderRootTab.upcoming)

            reminderTab(for: .later, path: $laterPath)
                .tag(ReminderRootTab.later)
        }
        .onAppear {
            if launchArguments.contains("UITEST_OPEN_UPCOMING") {
                selectedTab = .upcoming
            }
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
        }
        .tabItem {
            Label(segment.tabTitle, systemImage: segment.iconName)
        }
    }
}

private enum ReminderRootTab: Hashable {
    case today
    case tomorrow
    case upcoming
    case later
}

enum ReminderRoute: Hashable {
    case segment(ReminderSegment)
}

#Preview("Empty State") {
    let container = TaskPreviewData.container()
    TaskPreviewData.ensureDefaultListExists(in: container.mainContext)
    return ContentView()
        .modelContainer(container)
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return ContentView()
        .modelContainer(container)
}
