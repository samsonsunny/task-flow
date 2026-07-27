import SwiftUI
import SwiftData

struct ListCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    let onCreate: (String, ReminderListGroup?) -> Void

    @State private var name = ""
    @State private var selectedGroup: ReminderListGroup?
    @State private var groups: [ReminderListGroup] = []
    @State private var showMiniSheet = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("List Name", text: $name)
                        .focused($isNameFocused)
                }

                Section {
                    HStack {
                        Text("Group (optional)")
                        Spacer()
                        Menu {
                            Button("None") { selectedGroup = nil }
                            if !groups.isEmpty {
                                Section("Existing Groups") {
                                    ForEach(groups) { group in
                                        Button(group.name) { selectedGroup = group }
                                    }
                                }
                            }
                            Divider()
                            Button("New Group\u{2026}") { showMiniSheet = true }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedGroup?.name ?? "None")
                                    .foregroundStyle(selectedGroup == nil ? .secondary : .primary)
                                Image(systemName: "chevron.up.down")
                                    .imageScale(.small)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(name, selectedGroup)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .sheet(isPresented: $showMiniSheet) {
            MiniCreationSheet(
                title: "New Group",
                placeholder: "Group Name",
                onCreate: { groupName in
                    let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let group = ReminderListGroup(name: trimmed)
                    modelContext.insert(group)
                    group.assignInitialSortOrder(in: modelContext)
                    try? modelContext.save()
                    fetchGroups()
                    selectedGroup = group
                }
            )
        }
        .onAppear {
            fetchGroups()
            isNameFocused = true
        }
    }

    private func fetchGroups() {
        let descriptor = FetchDescriptor<ReminderListGroup>(sortBy: [SortDescriptor(\.name)])
        groups = (try? modelContext.fetch(descriptor)) ?? []
    }
}
