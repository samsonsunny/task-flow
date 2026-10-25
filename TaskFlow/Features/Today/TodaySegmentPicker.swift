import SwiftUI

struct TodaySegmentPicker: View {
    @Binding var selection: TodayTaskListView.TodaySegment

    var body: some View {
        HStack(spacing: 24) {
            ForEach(TodayTaskListView.TodaySegment.allCases, id: \.self) { segment in
                Button {
                    if selection != segment {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = segment
                    }
                } label: {
                    Text(segment.rawValue)
                        .font(selection == segment ? .largeTitle.bold() : .system(size: 30, weight: .regular))
                        .foregroundStyle(selection == segment ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary)
                        .frame(minHeight: 44, alignment: .topLeading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .fixedSize()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
