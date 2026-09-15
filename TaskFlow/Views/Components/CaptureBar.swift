import SwiftUI

struct CaptureBar: View {
    let viewModel: CaptureBarViewModel
    let onCommit: (String, String) -> Void
    var autofocusRequest: Bool = false

    @FocusState private var isFocused: Bool

    private var textBinding: Binding<String> {
        Binding(
            get: { viewModel.text },
            set: { viewModel.text = $0 }
        )
    }

    private var isBarIdle: Bool {
        !isFocused && viewModel.text.isEmpty
    }

    private var hasValidContent: Bool {
        !viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 10) {
            if isBarIdle {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.primaryAction)
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("capture-bar-plus")
            }

            ZStack(alignment: .topLeading) {
                TextField("", text: textBinding, axis: .vertical)
                    .focused($isFocused)
                    .lineLimit(1...5)
                    .frame(minHeight: 28, alignment: .center)
                    .submitLabel(.return)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityIdentifier("capture-bar-field")
                    .onSubmit { commit() }
                    .onChange(of: viewModel.text) { _, newValue in
                        guard newValue.contains("\n") else { return }
                        viewModel.text = newValue.replacingOccurrences(of: "\n", with: "")
                        commit()
                    }

                if viewModel.text.isEmpty {
                    Text("Add a task...")
                        .foregroundStyle(AppTheme.colors.textSecondary)
                        .frame(minHeight: 28, alignment: .center)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 48)
        }
        .padding(.leading, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .animation(.easeInOut(duration: 0.15), value: isBarIdle)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 5)
        .overlay(alignment: .bottomTrailing) {
            Button {
                commit()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textOnPrimaryAction)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(AppTheme.colors.primaryAction))
            }
            .buttonStyle(.plain)
            .opacity(hasValidContent ? 1 : 0)
            .allowsHitTesting(hasValidContent)
            .disabled(!hasValidContent)
            .animation(.easeInOut(duration: 0.15), value: hasValidContent)
            .accessibilityIdentifier("capture-bar-submit")
            .padding(.trailing, 14)
            .padding(.bottom, 10)
        }
        .padding(.horizontal, isFocused ? 8 : 32)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .onChange(of: autofocusRequest) { _, requested in
            if requested {
                isFocused = true
                viewModel.isFocusingCapture = false
            }
        }
        .onAppear {
            if autofocusRequest {
                isFocused = true
                viewModel.isFocusingCapture = false
            }
        }
    }

    private func commit() {
        let t = viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else {
            isFocused = false
            return
        }
        viewModel.text = ""
        viewModel.isFocusingCapture = false
        onCommit(t, "")
    }
}