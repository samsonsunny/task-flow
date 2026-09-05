import SwiftUI

struct TomorrowView: View {
    let headerAccessory: (() -> AnyView)?

    init(headerAccessory: (() -> AnyView)? = nil) {
        self.headerAccessory = headerAccessory
    }

    var body: some View {
        ReminderSegmentDetailView(segment: .tomorrow, headerAccessory: headerAccessory)
    }
}