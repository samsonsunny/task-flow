import SwiftUI
import SwiftData

struct ListCreationSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// The area the new list will belong to. There is no area picker: the list always lands
    /// in the selected area, and the copy below states that destination so it is never
    /// ambiguous.
    let areaName: String
    let onCreate: (String) -> Void

    @State private var name = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("List Name", text: $name)
                        .focused($isNameFocused)
                }

                Section {
                    LabeledContent("Creates a list in", value: areaName)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("This list will appear under \(areaName) on Home.")
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
                        onCreate(name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { isNameFocused = true }
    }
}
