import SwiftUI

struct TomorrowView: View {
    let onSettings: () -> Void

    var body: some View {
        NavigationStack {
            ReminderSegmentDetailView(segment: .tomorrow)
                .navigationTitle(ReminderSegment.tomorrow.title)
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
