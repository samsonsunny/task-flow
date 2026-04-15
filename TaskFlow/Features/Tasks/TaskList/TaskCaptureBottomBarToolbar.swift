import SwiftUI

struct TaskCaptureBottomBarToolbar: ToolbarContent {
    @Binding var title: String
    let onSubmit: () -> Void
    let captureFocused: FocusState<Bool>.Binding

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            TextField("What's on your mind?", text: $title)
                .font(.default)
                .submitLabel(.done)
                .onSubmit(onSubmit)
                .textFieldStyle(.plain)
                .focused(captureFocused)
                .padding(.horizontal, 8)
        }
    }
}
