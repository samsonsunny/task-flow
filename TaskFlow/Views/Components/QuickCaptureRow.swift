import SwiftUI

extension Notification.Name {
    static let quickCaptureCommitted = Notification.Name("quickCaptureCommitted")
}

struct QuickCaptureRow: View {
    @Binding var text: String
    let onSubmit: (String, String) -> Void
    let onDismiss: () -> Void

    @FocusState private var isFocused: Bool
    @State private var isNotesExpanded = false
    @State private var notes = ""
    @FocusState private var isNotesFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
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

                if !text.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isNotesExpanded.toggle()
                        }
                        if isNotesExpanded {
                            isNotesFocused = true
                        }
                    } label: {
                        Image(systemName: isNotesExpanded ? "note.text" : "note")
                            .font(.system(size: 16))
                            .foregroundStyle(isNotesExpanded ? AppTheme.colors.primaryAction : AppTheme.colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("quick-capture-notes-toggle")
                }
            }
            .id("quick-capture")
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            if isNotesExpanded {
                TextField("Add notes", text: $notes, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(1...4)
                    .focused($isNotesFocused)
                    .padding(.leading, 36)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                submitAndDismiss()
            }
        }
    }

    private func submitAndDismiss() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let n = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        text = ""
        notes = ""
        isNotesExpanded = false
        if !t.isEmpty { onSubmit(t, n) }
        onDismiss()
    }

    private func handleSubmit() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else {
            isFocused = false
            return
        }
        let n = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        text = ""
        notes = ""
        isNotesExpanded = false
        onSubmit(t, n)
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
