import SwiftUI

struct TaskListSidebarView: View {
    @Binding var selectedDestination: SidebarDestination
    @Binding var splitViewVisibility: NavigationSplitViewVisibility

    var body: some View {
        List(selection: selection) {
            Section("Views") {
                ForEach([TaskBucket.today, .tomorrow, .upcoming]) { bucket in
                    Label(bucket.title, systemImage: bucket.iconName)
                        .tag(SidebarDestination.bucket(bucket))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDestination = .bucket(bucket)
                            splitViewVisibility = .detailOnly
                        }
                }
            }
            Section("Someday") {
                Label(TaskBucket.someday.title, systemImage: TaskBucket.someday.iconName)
                    .tag(SidebarDestination.bucket(.someday))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDestination = .bucket(.someday)
                        splitViewVisibility = .detailOnly
                    }
            }
        }
        .navigationTitle("TaskFlow")
    }

    private var selection: Binding<SidebarDestination?> {
        Binding(
            get: { selectedDestination },
            set: { newValue in
                guard let newValue else { return }
                selectedDestination = newValue
            }
        )
    }
}
