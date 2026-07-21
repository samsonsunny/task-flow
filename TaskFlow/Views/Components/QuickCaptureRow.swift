import SwiftUI

extension Notification.Name {
    static let quickCaptureCommitted = Notification.Name("quickCaptureCommitted")
}

struct QuickCaptureRow: View {
    @Binding var text: String
    let onSubmit: (String) -> Void
    let onDismiss: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppTheme.colors.primaryAction)
                .frame(width: 20, height: 20)

            NonDismissingTextField(
                text: $text,
                placeholder: "New Reminder",
                onSubmit: handleSubmit,
                isFocused: $isFocused
            )
            .accessibilityIdentifier("quick-capture-field")
        }
        .id("quick-capture")
        .padding(.vertical, 9)
        .padding(.horizontal, 16)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                text = ""
                if !t.isEmpty { onSubmit(t) }
                onDismiss()
            }
        }
    }

    private func handleSubmit() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else {
            isFocused = false
            return
        }
        text = ""
        onSubmit(t)
        NotificationCenter.default.post(name: .quickCaptureCommitted, object: nil)
    }
}

extension View {
    func quickCaptureScroll(isActive: Bool, proxy: ScrollViewProxy, fieldID: String = "quick-capture") -> some View {
        self
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    DispatchQueue.main.async {
                        withAnimation { proxy.scrollTo(fieldID, anchor: .bottom) }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                guard isActive else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(fieldID, anchor: .bottom)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .quickCaptureCommitted)) { _ in
                guard isActive else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(fieldID, anchor: .bottom)
                    }
                }
            }
    }
}
