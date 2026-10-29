import SwiftUI
import SwiftData
import UIKit

/// The app's root navigation surface.
///
/// Exactly four fixed tabs: Today shows what is due now across both domains, Work and
/// Personal show every incomplete task filed in that domain, and More holds domain list
/// management, activity, notifications, and settings. Projects/lists never become tabs.
struct MainTabView: View {
    enum AppTab: Hashable {
        case today
        case work
        case personal
        case more
    }

    @Environment(AppState.self) private var appState
    @State private var selectedTab: AppTab = .today

    var body: some View {
        MainTabBarController(
            selection: $selectedTab,
            onTabReselected: { tab in
                switch tab {
                case .today: appState.requestTodayReset()
                case .work: appState.requestScrollToTop(id: AreaNames.work)
                case .personal: appState.requestScrollToTop(id: AreaNames.personal)
                case .more: appState.requestScrollToTop(id: "more")
                }
            },
            todayView: { TodayTaskListView() },
            workView: { AreaTasksView(areaName: AreaNames.work, storageKey: AreaNames.work) },
            personalView: { AreaTasksView(areaName: AreaNames.personal, storageKey: AreaNames.personal) },
            moreView: { MoreView() }
        )
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct MainTabBarController: UIViewControllerRepresentable {
    @Binding var selection: MainTabView.AppTab
    let onTabReselected: (MainTabView.AppTab) -> Void
    let todayView: () -> TodayTaskListView
    let workView: () -> AreaTasksView
    let personalView: () -> AreaTasksView
    let moreView: () -> MoreView

    func makeUIViewController(context: Context) -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.delegate = context.coordinator
        tabBarController.tabBar.tintColor = UIColor(AppTheme.colors.tint)

        let todayVC = UIHostingController(rootView: todayView())
        todayVC.tabBarItem = UITabBarItem(title: "Today", image: UIImage(systemName: "text.rectangle.page"), tag: 0)

        let workVC = UIHostingController(rootView: workView())
        workVC.tabBarItem = UITabBarItem(title: "Work", image: UIImage(systemName: "briefcase.fill"), tag: 1)

        let personalVC = UIHostingController(rootView: personalView())
        personalVC.tabBarItem = UITabBarItem(title: "Personal", image: UIImage(systemName: "person.crop.circle.fill"), tag: 2)

        let moreVC = UIHostingController(rootView: moreView())
        moreVC.tabBarItem = UITabBarItem(title: "More", image: UIImage(systemName: "square.grid.2x2.fill"), tag: 3)

        tabBarController.viewControllers = [todayVC, workVC, personalVC, moreVC]
        return tabBarController
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
        let tag: Int
        switch selection {
        case .today: tag = 0
        case .work: tag = 1
        case .personal: tag = 2
        case .more: tag = 3
        }
        if uiViewController.selectedIndex != tag {
            uiViewController.selectedIndex = tag
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITabBarControllerDelegate {
        var parent: MainTabBarController

        init(_ parent: MainTabBarController) {
            self.parent = parent
        }

        func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
            if tabBarController.selectedViewController == viewController {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                parent.onTabReselected(Self.tab(for: tabBarController.selectedIndex))
                return false
            }
            return true
        }

        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            switch tabBarController.selectedIndex {
            case 0:
                if parent.selection == .today {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    parent.onTabReselected(.today)
                    return
                }
                parent.selection = .today
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            case 1:
                parent.selection = .work
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            case 2:
                parent.selection = .personal
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            case 3:
                parent.selection = .more
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            default: break
            }
        }

        private static func tab(for index: Int) -> MainTabView.AppTab {
            switch index {
            case 0: .today
            case 1: .work
            case 2: .personal
            default: .more
            }
        }
    }
}

#Preview("Empty State") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedDefaultAreas(in: container.mainContext)
    return MainTabView()
        .modelContainer(container)
        .environment(AppState())
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedBothAreasFixture(into: container)
    return MainTabView()
        .modelContainer(container)
        .environment(AppState())
}
