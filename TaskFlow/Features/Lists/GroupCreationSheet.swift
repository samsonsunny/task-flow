import SwiftUI
import SwiftData

struct GroupCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    let initialList: ReminderList?
    let onCreate: (String, ReminderList?) -> Void

    @State private var name = ""
    @State private var selectedList: ReminderList?
    @State private var ungroupedLists: [ReminderList] = []
    @State private var showMiniSheet = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group Name", text: $name)
                        .focused($isNameFocused)
                }

                Section {
                    if !ungroupedLists.isEmpty {
                        HStack {
                            Text("Add List (optional)")
                            Spacer()
                            Menu {
                                Button("None") { selectedList = nil }
                                Section("Ungrouped Lists") {
                                    ForEach(ungroupedLists) { list in
                                        Button(list.name) { selectedList = list }
                                    }
                                }
                                Divider()
                                Button("New List\u{2026}") { showMiniSheet = true }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(selectedList?.name ?? "None")
                                        .foregroundStyle(selectedList == nil ? .secondary : .primary)
                                    Image(systemName: "chevron.up.down")
                                        .imageScale(.small)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        Button("New List\u{2026}") { showMiniSheet = true }
                    }
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(name, selectedList)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .sheet(isPresented: $showMiniSheet) {
            MiniCreationSheet(
                title: "New List",
                placeholder: "List Name",
                onCreate: { listName in
                    let trimmed = listName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let list = ReminderList(name: trimmed)
                    modelContext.insert(list)
                    list.assignInitialSortOrder(in: modelContext)
                    try? modelContext.save()
                    fetchLists()
                    selectedList = list
                }
            )
        }
        .onAppear {
            fetchLists()
            if let initialList {
                selectedList = initialList
            }
            isNameFocused = true
        }
    }

    private func fetchLists() {
        let descriptor = FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.name)])
        let allLists = (try? modelContext.fetch(descriptor)) ?? []
        ungroupedLists = allLists.filter { $0.group == nil && $0.name != ReminderDefaults.defaultListName }
    }
}
