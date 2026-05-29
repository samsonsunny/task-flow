import SwiftUI

public struct TaskScheduleDatePickerSheet: View {
    @Binding var isPresented: Bool
    @Binding var chosenDate: Date
    var onChooseDate: (Date) -> Void
    
    public init(isPresented: Binding<Bool>, chosenDate: Binding<Date>, onChooseDate: @escaping (Date) -> Void) {
        self._isPresented = isPresented
        self._chosenDate = chosenDate
        self.onChooseDate = onChooseDate
    }
    
    public var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Choose a date",
                    selection: $chosenDate,
                    in: Date.distantPast...Date.distantFuture,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding()
                Spacer()
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Select Date")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onChooseDate(chosenDate)
                        isPresented = false
                    }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }
}
