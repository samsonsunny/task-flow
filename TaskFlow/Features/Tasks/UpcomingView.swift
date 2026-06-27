import SwiftUI

struct UpcomingView: View {
    let onSettings: () -> Void

    var body: some View {
        NavigationStack {
            ReminderSegmentDetailView(segment: .upcoming)
                .navigationTitle(ReminderSegment.upcoming.title)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            onSettings()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
    }
}
