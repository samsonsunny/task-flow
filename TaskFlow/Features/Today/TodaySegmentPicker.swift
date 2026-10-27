import SwiftUI

struct TodaySegmentPicker: View {
    @Binding var selection: TodayTaskListView.TodaySegment
    let workHasIndicator: Bool
    let personalHasIndicator: Bool

    init(selection: Binding<TodayTaskListView.TodaySegment>, workHasIndicator: Bool = false, personalHasIndicator: Bool = false) {
        self._selection = selection
        self.workHasIndicator = workHasIndicator
        self.personalHasIndicator = personalHasIndicator
    }

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
                        .font(selection == segment ? .largeTitle.bold() : .title.weight(.semibold))
                        .foregroundStyle(selection == segment ? AppTheme.colors.tint : AppTheme.colors.textSecondary)
                        .frame(minHeight: 44, alignment: .bottomLeading)
                        .contentShape(Rectangle())
                        .overlay(alignment: .topTrailing) {
                            if selection != segment {
                                let has = segment == .work ? workHasIndicator : personalHasIndicator
                                if has {
                                    Circle()
                                        .fill(AppTheme.colors.error)
                                        .frame(width: 6, height: 6)
                                        .offset(x: 8, y: 12)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
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
