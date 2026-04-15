import SwiftUI

struct TaskScheduleDatePickerSheet: View {
    @Binding var isPresented: Bool
    @Binding var chosenDate: Date
    let onChooseDate: (Date) -> Void

    var body: some View {
        NavigationStack {
            DatePicker(
                "Choose Day",
                selection: Binding(
                    get: { chosenDate },
                    set: { newValue in
                        let normalized = Calendar.current.startOfDay(for: newValue)
                        chosenDate = normalized
                        onChooseDate(normalized)
                    }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding()
            .navigationTitle("Schedule")
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

