import SwiftUI

struct NonDismissingTextField: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .focused($isFocused)
            .onSubmit {
                onSubmit()
            }
            .textInputAutocapitalization(.sentences)
    }
}
