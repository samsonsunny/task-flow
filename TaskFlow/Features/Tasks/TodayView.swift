import SwiftUI

struct TodayTabView: View {
    let onSettings: () -> Void
    @State private var isSelecting = false

    var body: some View {
        NavigationStack {
            ReminderSegmentDetailView(segment: .today, isSelecting: $isSelecting)
                .navigationTitle(ReminderSegment.today.navigationTitle)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if isSelecting {
                            Button("Done") {
                                isSelecting = false
                            }
                        } else {
                            Menu {
                                Button("Select Items") {
                                    isSelecting = true
                                }
                                Divider()
                                Button {
                                    onSettings()
                                } label: {
                                    Label("Settings", systemImage: "gearshape")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        }
                    }
                }
        }
    }
}
