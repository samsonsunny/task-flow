import SwiftUI

struct TaskCaptureDatePickerSheet: View {
    @Binding var isPresented: Bool
    @Binding var chosenDate: Date
    @Binding var dueSelection: CaptureDueSelection?

    var body: some View {
        NavigationStack {
            DatePicker(
                "Choose Day",
                selection: Binding(
                    get: { chosenDate },
                    set: { newValue in
                        let normalized = Calendar.current.startOfDay(for: newValue)
                        chosenDate = normalized
                        dueSelection = .chooseDay(normalized)
                    }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding()
            .navigationTitle("Choose Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
