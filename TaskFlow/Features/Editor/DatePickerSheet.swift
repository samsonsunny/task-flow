import SwiftUI

public struct TaskScheduleDatePickerSheet: View {
    @Binding var isPresented: Bool
    var onCommit: (Date?, Bool) -> Void

    @State private var viewModel: TaskScheduleDatePickerViewModel

    public init(
        isPresented: Binding<Bool>,
        initialDueDate: Date?,
        initialFocus: ExpandedPicker? = nil,
        onCommit: @escaping (Date?, Bool) -> Void
    ) {
        self._isPresented = isPresented
        self.onCommit = onCommit
        self._viewModel = State(initialValue: TaskScheduleDatePickerViewModel(
            initialDueDate: initialDueDate,
            initialFocus: initialFocus
        ))
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    dateRow
                    if viewModel.expandedPicker == .date {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.dueDate ?? Date() },
                                set: { viewModel.dueDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .padding(.horizontal)
                        .transition(.push(from: .top))
                    }

                    timeRow
                    if viewModel.expandedPicker == .time {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.dueDate ?? Date() },
                                set: { viewModel.dueDate = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 150)
                        .clipped()
                        .transition(.push(from: .top))
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .background(.ultraThinMaterial)
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onCommit(viewModel.dueDate, viewModel.hasTime)
                        isPresented = false
                    }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
        .animation(.smooth(duration: 0.3), value: viewModel.expandedPicker)
    }

    private var dateRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Date")
                if let date = viewModel.dueDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Toggle("Date", isOn: Binding(
                get: { viewModel.dueDate != nil },
                set: { viewModel.toggleDate(isEnabled: $0) }
            ))
            .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            guard viewModel.dueDate != nil else { return }
            viewModel.expandedPicker = viewModel.expandedPicker == .date ? nil : .date
        }
    }

    private var timeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Time")
                if viewModel.hasTime, let date = viewModel.dueDate {
                    Text(date, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Toggle("Time", isOn: Binding(
                get: { viewModel.hasTime },
                set: { viewModel.toggleTime(isEnabled: $0) }
            ))
            .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            guard viewModel.hasTime else { return }
            viewModel.expandedPicker = viewModel.expandedPicker == .time ? nil : .time
        }
    }
}
