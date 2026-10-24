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
                    VStack(alignment: .leading, spacing: 6) {
                        Text(segment.rawValue)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(selection == segment ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary)
                        Rectangle()
                            .fill(selection == segment ? AppTheme.colors.tint : Color.clear)
                            .frame(height: 3)
                    }
                }
                .buttonStyle(.plain)
                .fixedSize()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
}
