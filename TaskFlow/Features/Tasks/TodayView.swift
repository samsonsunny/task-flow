import SwiftUI

struct TodayTabView: View {
    let onSettings: () -> Void

    var body: some View {
        NavigationStack {
            ReminderSegmentDetailView(segment: .today)
                .navigationTitle(ReminderSegment.today.title)
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
