import SwiftUI

struct NonDismissingTextField: UIViewRepresentable {
    @Binding var text: String
    let onSubmit: () -> Void
    @Binding var isFocused: Bool

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = "New Reminder"
        textField.font = .systemFont(ofSize: 17)
        textField.textColor = UIColor(AppTheme.colors.textPrimary)
        textField.delegate = context.coordinator
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.required, for: .vertical)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if isFocused != uiView.isFirstResponder {
            if isFocused {
                uiView.becomeFirstResponder()
            } else {
                uiView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit, isFocused: $isFocused)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        let onSubmit: () -> Void
        @Binding var isFocused: Bool

        init(text: Binding<String>, onSubmit: @escaping () -> Void, isFocused: Binding<Bool>) {
            self._text = text
            self.onSubmit = onSubmit
            self._isFocused = isFocused
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            DispatchQueue.main.async {
                self.text = textField.text ?? ""
            }
            return true
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            text = textField.text ?? ""
            onSubmit()
            return false
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            text = textField.text ?? ""
            isFocused = false
        }
    }
}
