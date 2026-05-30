import SwiftUI
import SwiftData

@Observable
final class AppState {
    var isSidebarOpen = false
    var selectedListId: ReminderList.ID?
    var pendingNavigation: ReminderRoute?
}
