import SwiftUI

struct UpcomingView: View {
    let headerAccessory: (() -> AnyView)?

    init(headerAccessory: (() -> AnyView)? = nil) {
        self.headerAccessory = headerAccessory
    }

    var body: some View {
        ReminderSegmentDetailView(segment: .upcoming, headerAccessory: headerAccessory)
    }
}