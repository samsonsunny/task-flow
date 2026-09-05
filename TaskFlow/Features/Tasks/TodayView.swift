import SwiftUI

struct TodayTabView: View {
    let headerAccessory: (() -> AnyView)?

    init(headerAccessory: (() -> AnyView)? = nil) {
        self.headerAccessory = headerAccessory
    }

    var body: some View {
        ReminderSegmentDetailView(segment: .today, headerAccessory: headerAccessory)
    }
}