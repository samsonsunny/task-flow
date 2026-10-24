import SwiftUI

private struct ChipFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct ScrollFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct DateStripView: View {
    let days: [Date]
    @Binding var selectedDate: Date
    let onGoToToday: () -> Void
    
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var viewSize: CGSize = .zero
    @State private var hasAppeared = false
    @State private var chipFrames: [String: CGRect] = [:]
    @State private var scrollFrame: CGRect = .zero
    @State private var suppressScrollOnNextChange = false
    
    private var sizeCategoryScale: CGFloat {
        switch sizeCategory {
        case .extraSmall: return 0.9
        case .small: return 0.95
        case .medium: return 1.0
        case .large: return 1.0
        case .extraLarge: return 1.05
        case .extraExtraLarge: return 1.1
        case .extraExtraExtraLarge: return 1.15
        case .accessibilityMedium: return 1.2
        case .accessibilityLarge: return 1.3
        case .accessibilityExtraLarge: return 1.4
        case .accessibilityExtraExtraLarge: return 1.5
        case .accessibilityExtraExtraExtraLarge: return 1.6
        @unknown default: return 1.0
        }
    }
    
    private let calendar = Calendar.current
    
    private static let spacing: CGFloat = 8
    private static let horizontalPadding: CGFloat = 20
    private static let baseChipHeight: CGFloat = 64
    private static let verticalPadding: CGFloat = 8
    private static let targetCount = 5
    
    private var chipHeight: CGFloat {
        max(Self.baseChipHeight, Self.baseChipHeight * sizeCategoryScale)
    }
    
    private var chipWidth: CGFloat {
        let availableWidth = viewSize.width - (Self.horizontalPadding * 2)
        guard availableWidth > 0 else { return 72 }
        return max(48, (availableWidth - Self.spacing * CGFloat(Self.targetCount - 1)) / CGFloat(Self.targetCount))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Self.spacing) {
                        ForEach(days, id: \.self) { date in
                            DateChip(
                                date: date,
                                width: chipWidth,
                                height: chipHeight,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                            ) {
                                select(date, proxy: proxy)
                            }
                            .id(dateKey(date))
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(
                                            key: ChipFramePreferenceKey.self,
                                            value: [dateKey(date): geo.frame(in: .named("DateStripScroll"))]
                                        )
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Self.horizontalPadding)
                    .frame(minHeight: chipHeight + Self.verticalPadding)
                }
                .coordinateSpace(name: "DateStripScroll")
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ScrollFramePreferenceKey.self,
                                value: geo.frame(in: .global)
                            )
                            .onAppear { viewSize = geo.size }
                            .onChange(of: geo.size) { _, newSize in viewSize = newSize }
                    }
                )
                .onPreferenceChange(ScrollFramePreferenceKey.self) { newValue in
                    scrollFrame = newValue
                }
                .onPreferenceChange(ChipFramePreferenceKey.self) { newValue in
                    chipFrames.merge(newValue, uniquingKeysWith: { $1 })
                }
                .onAppear {
                    if !hasAppeared {
                        let today = calendar.startOfDay(for: Date())
                        if selectedDate != today {
                            selectedDate = today
                        }
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(dateKey(today), anchor: .leading)
                            }
                            hasAppeared = true
                        }
                    } else {
                        if !isFullyVisible(dateKey(selectedDate)) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(dateKey(selectedDate), anchor: .center)
                            }
                        }
                    }
                }
                .onChange(of: selectedDate) { _, newValue in
                    if suppressScrollOnNextChange {
                        suppressScrollOnNextChange = false
                        return
                    }
                    let key = dateKey(newValue)
                    if isFullyVisible(key) {
                        return
                    }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(key, anchor: .center)
                    }
                }
            }
        }
        .frame(height: chipHeight + Self.verticalPadding)
    }
    
    private func dateKey(_ date: Date) -> String {
        String(calendar.startOfDay(for: date).timeIntervalSinceReferenceDate)
    }
    
    private func isFullyVisible(_ key: String) -> Bool {
        guard let frame = chipFrames[key] else { return false }
        let paddedLeft = scrollFrame.origin.x + Self.horizontalPadding
        let paddedRight = scrollFrame.origin.x + scrollFrame.width - Self.horizontalPadding
        return frame.minX >= paddedLeft - 2 && frame.maxX <= paddedRight + 2
    }
    
    private func scrollToVisibleIfNeeded(_ key: String, proxy: ScrollViewProxy, force: Bool) {
        if force {
            if isFullyVisible(key) {
                return
            }
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(key, anchor: .center)
            }
            return
        }
        if isFullyVisible(key) {
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            proxy.scrollTo(key, anchor: .center)
        }
    }
    
    private func select(_ date: Date, proxy: ScrollViewProxy) {
        let startOfDay = calendar.startOfDay(for: date)
        if calendar.isDateInToday(startOfDay) && selectedDate == startOfDay {
            // Tapping today when already selected refreshes the page
            NotificationCenter.default.post(name: .todayRefreshRequested, object: nil)
            return
        }
        let key = dateKey(startOfDay)
        if selectedDate == startOfDay {
            if !isFullyVisible(key) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(key, anchor: .center)
                }
            }
            return
        }
        if selectedDate != startOfDay {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if isFullyVisible(key) {
            suppressScrollOnNextChange = true
            selectedDate = startOfDay
            return
        }
        selectedDate = startOfDay
        withAnimation(.easeInOut(duration: 0.25)) {
            proxy.scrollTo(key, anchor: .center)
        }
    }
}
