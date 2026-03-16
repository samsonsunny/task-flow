import SwiftUI

struct TaskCaptureBarView: View {
    @Binding var title: String
    @Binding var dueSelection: CaptureDueSelection?
    @Binding var isDatePickerPresented: Bool
    @Binding var chosenDate: Date
    let selectedBucket: TaskBucket
    let onSubmit: () -> Void
    let captureFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: 10) {
            dueChips

            HStack(spacing: 10) {
                TextField("What's on your mind?", text: $title, axis: .vertical)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppTheme.colors.textPrimary)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .multilineTextAlignment(.leading)
                    .focused(captureFocused)

                if hasContent {
                    Button {
                        onSubmit()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.colors.textPrimary)
                }
            }
            .padding(.vertical, TaskListCaptureMetrics.inputVerticalPadding)
            .padding(.horizontal, TaskListCaptureMetrics.inputHorizontalPadding)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: TaskListCaptureMetrics.cornerRadius)
                    .stroke(AppTheme.colors.border.opacity(0.7), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: TaskListCaptureMetrics.cornerRadius))
        }
        .padding(.top, 10)
        .padding(.horizontal, TaskListCaptureMetrics.horizontalScreenInset)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.colors.border.opacity(0.35))
                .frame(height: 0.5)
        }
    }

    private var hasContent: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var dueChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "Today", selection: .today)
                chip(title: "Tomorrow", selection: .tomorrow)
                chip(title: "Someday", selection: .someday)
                chooseDayChip
            }
            .padding(.horizontal, 2)
        }
    }

    private func chip(title: String, selection: CaptureDueSelection) -> some View {
        buttonChip(title: title, isSelected: isSelected(selection)) {
            dueSelection = selection
        }
    }

    private var chooseDayChip: some View {
        buttonChip(title: chooseDayChipTitle, isSelected: isChooseDaySelected) {
            dueSelection = .chooseDay(chosenDate)
            isDatePickerPresented = true
        }
    }

    private func buttonChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isSelected ? .regularMaterial : .thinMaterial)
                .overlay(
                    Capsule()
                        .stroke(AppTheme.colors.border.opacity(isSelected ? 0.75 : 0.4), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var chooseDayChipTitle: String {
        let calendar = Calendar.current
        let effective = effectiveDueSelection(for: selectedBucket)
        guard case .chooseDay = effective else {
            return "Choose Day"
        }
        let formatter = TaskListView.chipDateFormatter
        return formatter.string(from: calendar.startOfDay(for: chosenDate))
    }

    private var isChooseDaySelected: Bool {
        let effective = effectiveDueSelection(for: selectedBucket)
        if case .chooseDay = effective { return true }
        return false
    }

    private func isSelected(_ selection: CaptureDueSelection) -> Bool {
        effectiveDueSelection(for: selectedBucket) == selection
    }

    private func effectiveDueSelection(for bucket: TaskBucket) -> CaptureDueSelection {
        dueSelection ?? defaultDueSelection(for: bucket)
    }

    private func defaultDueSelection(for bucket: TaskBucket) -> CaptureDueSelection {
        let calendar = Calendar.current
        switch bucket {
        case .today:
            return .today
        case .tomorrow:
            return .tomorrow
        case .someday:
            return .someday
        case .upcoming:
            let todayStart = calendar.startOfDay(for: Date())
            let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: todayStart) ?? todayStart
            return .chooseDay(dayAfterTomorrow)
        }
    }
}
