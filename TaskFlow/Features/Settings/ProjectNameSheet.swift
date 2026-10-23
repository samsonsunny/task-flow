import SwiftUI

struct ProjectNameSheet: View {
    @Environment(\.dismiss) private var dismiss

    var title = "New Project"
    var confirmTitle = "Create"
    var footerText = "Lists you create inside a project are grouped under it."
    var initialName = ""

    /// Returns `false` when the name is invalid or already taken, so the sheet can keep the
    /// user's input instead of dismissing on a failed save.
    let onCommit: (String) -> Bool

    @State private var name: String
    @State private var errorMessage: String?
    @FocusState private var isNameFocused: Bool

    init(
        title: String = "New Project",
        confirmTitle: String = "Create",
        footerText: String = "Lists you create inside a project are grouped under it.",
        initialName: String = "",
        onCommit: @escaping (String) -> Bool
    ) {
        self.title = title
        self.confirmTitle = confirmTitle
        self.footerText = footerText
        self.initialName = initialName
        self.onCommit = onCommit
        _name = State(initialValue: initialName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project Name", text: $name)
                        .focused($isNameFocused)
                } footer: {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    } else {
                        Text(footerText)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmTitle) {
                        commit()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear { isNameFocused = true }
        .onChange(of: name) { _, _ in errorMessage = nil }
    }

    private func commit() {
        guard onCommit(name) else {
            errorMessage = "That name is reserved or already used by another project."
            return
        }
        Haptics.success()
        dismiss()
    }
}
