import SwiftUI

public struct TaskScheduleDatePickerSheet: View {
    @Binding var isPresented: Bool
    var onCommit: (Date?, Bool) -> Void

    @State private var dueDate: Date?
    @State private var hasTime: Bool
    @State private var expandedPicker: ExpandedPicker?

    public init(
        isPresented: Binding<Bool>,
        initialDueDate: Date?,
        onCommit: @escaping (Date?, Bool) -> Void
    ) {
        self._isPresented = isPresented
        self.onCommit = onCommit
        let hasTimeVal: Bool
        if let date = initialDueDate {
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            hasTimeVal = components.hour != 0 || components.minute != 0
        } else {
            hasTimeVal = false
        }
        self._dueDate = State(initialValue: initialDueDate)
        self._hasTime = State(initialValue: hasTimeVal)
        self._expandedPicker = State(initialValue: initialDueDate != nil ? .date : nil)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    dateRow
                    if expandedPicker == .date {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { newDate in dueDate = newDate }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .padding(.horizontal)
                        .transition(.push(from: .top))
                    }

                    timeRow
                    if expandedPicker == .time {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { newDate in dueDate = newDate }
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
                        onCommit(dueDate, hasTime)
                        isPresented = false
                    }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
        .animation(.smooth(duration: 0.3), value: expandedPicker)
    }

    private var dateRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Date")
                if let date = dueDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Toggle("Date", isOn: Binding(
                get: { dueDate != nil },
                set: { isEnabled in
                    if isEnabled {
                        dueDate = dueDate ?? Date()
                        expandedPicker = .date
                    } else {
                        dueDate = nil
                        hasTime = false
                        expandedPicker = nil
                    }
                }
            ))
            .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            guard dueDate != nil else { return }
            expandedPicker = expandedPicker == .date ? nil : .date
        }
    }

    private var timeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Time")
                if hasTime, let date = dueDate {
                    Text(date, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Toggle("Time", isOn: Binding(
                get: { hasTime },
                set: { isEnabled in
                    if isEnabled {
                        hasTime = true
                        let calendar = Calendar.current
                        let baseDate = dueDate ?? Date()
                        var dayComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
                        let rounded = nearestRoundedHour()
                        let timeComponents = calendar.dateComponents([.hour, .minute], from: rounded)
                        dayComponents.hour = timeComponents.hour
                        dayComponents.minute = timeComponents.minute
                        dueDate = calendar.date(from: dayComponents) ?? rounded
                        expandedPicker = .time
                    } else {
                        hasTime = false
                        expandedPicker = nil
                    }
                }
            ))
            .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            guard hasTime else { return }
            expandedPicker = expandedPicker == .time ? nil : .time
        }
    }

    private func nearestRoundedHour() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let totalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let rounded = ((totalMinutes + 29) / 30) * 30
        let clamped = rounded % (24 * 60)
        return calendar.date(bySettingHour: clamped / 60, minute: clamped % 60, second: 0, of: now) ?? now
    }

    private enum ExpandedPicker {
        case date
        case time
    }
}
