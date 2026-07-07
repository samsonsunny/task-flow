import SwiftUI

struct MiniCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let placeholder: String
    let onCreate: (String) -> Void

    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(placeholder, text: $name)
                    .autocorrectionDisabled()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onCreate(name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
