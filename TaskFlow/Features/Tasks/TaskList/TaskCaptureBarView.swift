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
        VStack(spacing: 8) {
            if shouldShowProgressiveControls {
                scheduleControl
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            ZStack(alignment: .bottomTrailing) {
                HStack(spacing: 8) {
                    if !hasNonWhitespaceText {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppTheme.colors.textSecondary)
                            .transition(.opacity)
                    }

                TextField(
                    "",
                    text: $title,
                    prompt: Text("What's on your mind?")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(AppTheme.colors.textSecondary),
                    axis: .vertical
                )
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppTheme.colors.textPrimary)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .multilineTextAlignment(.leading)
                    .focused(captureFocused)
                    .tint(AppTheme.colors.primaryAction)
                    .frame(minHeight: 48, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, shouldShowProgressiveControls ? 44 : 0)
                }

                if shouldShowProgressiveControls {
                    Button {
                        onSubmit()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.colors.primaryAction)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
                    .transition(.opacity)
                }
            }
            .padding(.vertical, TaskListCaptureMetrics.inputVerticalPadding)
            .padding(.horizontal, TaskListCaptureMetrics.inputHorizontalPadding)
            .frame(minHeight: 56, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: TaskListCaptureMetrics.cornerRadius, style: .continuous)
                    .fill(AppTheme.colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TaskListCaptureMetrics.cornerRadius, style: .continuous)
                    .stroke(AppTheme.colors.borderSubtle, lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.14), value: shouldShowProgressiveControls)
        .padding(.top, 10)
        .padding(.horizontal, TaskListCaptureMetrics.horizontalScreenInset)
        .padding(.bottom, 10)
    }

    private var isCaptureFocused: Bool { captureFocused.wrappedValue }

    private var hasNonWhitespaceText: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var shouldShowProgressiveControls: Bool {
        isCaptureFocused && hasNonWhitespaceText
    }

    private var scheduleControl: some View {
        Menu {
            Button("Today") { dueSelection = .today }
            Button("Tomorrow") { dueSelection = .tomorrow }
            Button("Someday") { dueSelection = .someday }
            Button("Pick Date") {
                dueSelection = .chooseDay(chosenDate)
                isDatePickerPresented = true
            }
        } label: {
            HStack(spacing: 6) {
                Text(scheduleLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.colors.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textSecondary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(AppTheme.colors.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.colors.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var scheduleLabel: String {
        switch effectiveDueSelection(for: selectedBucket) {
        case .today:
            return "Today"
        case .tomorrow:
            return "Tomorrow"
        case .someday:
            return "Someday"
        case .chooseDay(let date):
            let formatter = TaskListView.chipDateFormatter
            return formatter.string(from: Calendar.current.startOfDay(for: date))
        }
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
