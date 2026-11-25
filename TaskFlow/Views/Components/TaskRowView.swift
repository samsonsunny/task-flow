//
//  TaskRowView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI
import SwiftData

enum DueDateAction {
    case none
    case today
    case tomorrow
    case thisWeekend
    case nextWeek
    case custom
}

/// The interactions every task row surface shares. Views supply the ViewModel calls; the
/// row owns the haptics and the mapping from a task to its row actions so Today, Agenda,
/// Calendar, Work and Personal cannot drift apart.
struct TaskRowActions {
    let toggleCompletion: (TaskItem) -> Void
    let reschedule: ((TaskItem, DueDateAction) -> Void)?
    let delete: (TaskItem) -> Void
    let open: (TaskItem) -> Void

    init(
        toggleCompletion: @escaping (TaskItem) -> Void,
        reschedule: ((TaskItem, DueDateAction) -> Void)? = nil,
        delete: @escaping (TaskItem) -> Void,
        open: @escaping (TaskItem) -> Void
    ) {
        self.toggleCompletion = toggleCompletion
        self.reschedule = reschedule
        self.delete = delete
        self.open = open
    }
}

struct TaskRowView: View, Equatable {
    let task: TaskItem
    var isCompletedVisualState: Bool = false
    var onToggleCompletion: () -> Void
    var onDueDateAction: ((DueDateAction) -> Void)? = nil
    var onMoveToList: ((ReminderList) -> Void)? = nil
    var listSections: [ListSection] = []
    var excludedListID: PersistentIdentifier? = nil
    var onDelete: (() -> Void)? = nil
    var onSwipeNextDay: (() -> Void)? = nil
    var onMoveToTop: (() -> Void)? = nil
    var onMoveToBottom: (() -> Void)? = nil
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    var showsDueDate: Bool = false
    var showsListName: Bool = true
    var showsGroupName: Bool = false
    var groupNameOverride: String? = nil
    var subtaskSummary: SubtaskSummary = .empty
    var isSelecting: Bool = false
    var isSelected: Bool = false
    var onSelectToggle: (() -> Void)? = nil
    var isExpanded: Bool = false
    var onToggleExpand: (() -> Void)? = nil
    /// ScrollView-based surfaces need their own swipe coordinator on iOS 26; `List` hosts
    /// the native one and must keep using it.
    var enablesFallbackSwipe = false

    @State private var swipeOffset: CGFloat = 0
    @State private var isSwipeRevealed = false

    private static let swipeActionWidth: CGFloat = 80

    private static let cachedDetector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()

    @State private var chipScale: CGFloat = 1
    @ScaledMetric(relativeTo: .body) private var checkboxSize: CGFloat = 22

    static func == (lhs: TaskRowView, rhs: TaskRowView) -> Bool {
        lhs.task.persistentModelID == rhs.task.persistentModelID
            && lhs.isCompletedVisualState == rhs.isCompletedVisualState
            && lhs.subtaskSummary == rhs.subtaskSummary
            && lhs.isSelecting == rhs.isSelecting
            && lhs.isSelected == rhs.isSelected
            && lhs.isExpanded == rhs.isExpanded
            && lhs.showsDueDate == rhs.showsDueDate
            && lhs.showsListName == rhs.showsListName
            && lhs.showsGroupName == rhs.showsGroupName
            && lhs.groupNameOverride == rhs.groupNameOverride
            && (lhs.onDelete != nil) == (rhs.onDelete != nil)
            && (lhs.onDueDateAction != nil) == (rhs.onDueDateAction != nil)
            && (lhs.onSelectToggle != nil) == (rhs.onSelectToggle != nil)
            && (lhs.onToggleExpand != nil) == (rhs.onToggleExpand != nil)
            && lhs.enablesFallbackSwipe == rhs.enablesFallbackSwipe
    }
    
    var body: some View {
        contentWithContextMenu
    }

    @ViewBuilder
    private var gestureContent: some View {
        if enablesFallbackSwipe {
            fallbackSwipeContent
        } else {
            nativeSwipeContent
        }
    }

    private var rowBackground: some View {
        isSelected ? AppTheme.colors.primaryAction.opacity(0.12) : Color.clear
    }

    private var nativeSwipeContent: some View {
        rowContent
            .background(rowBackground)
            .animation(.easeInOut(duration: 0.18), value: isSelected)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if let onDelete, !isSelecting {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                if let onSwipeNextDay, !isSelecting {
                    Button {
                        onSwipeNextDay()
                    } label: {
                        Label("Postpone", systemImage: "arrow.right")
                    }
                    .tint(AppTheme.colors.tint)
                }
            }
    }

    /// SwiftUI only hosts `.swipeActions` in a `List` before iOS 27. Scroll-based surfaces
    /// use this equivalent trailing delete action through the same shared row component.
    private var fallbackSwipeContent: some View {
        ZStack(alignment: .trailing) {
            if canSwipeToDelete {
                Button {
                    closeSwipe()
                    onDelete?()
                } label: {
                    Image(systemName: "trash")
                        .font(AppFont.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: Self.swipeActionWidth, height: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(AppTheme.colors.error)
                .opacity(isSwipeRevealed || swipeOffset < 0 ? 1 : 0)
                .accessibilityLabel("Delete")
            }

            rowContent
                .background(rowBackground)
                .animation(.easeInOut(duration: 0.18), value: isSelected)
                .offset(x: swipeOffset)
                .simultaneousGesture(swipeGesture)
        }
        .clipped()
    }

    private var canSwipeToDelete: Bool {
        onDelete != nil && !isSelecting
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard canSwipeToDelete,
                      abs(value.translation.width) > abs(value.translation.height)
                else { return }
                let base: CGFloat = isSwipeRevealed ? -Self.swipeActionWidth : 0
                swipeOffset = max(-Self.swipeActionWidth, min(0, base + value.translation.width))
            }
            .onEnded { value in
                guard canSwipeToDelete else { return }
                let predicted = value.predictedEndTranslation.width
                let shouldReveal = isSwipeRevealed
                    ? predicted > -Self.swipeActionWidth / 2
                    : predicted < -Self.swipeActionWidth / 2
                withAnimation(.easeOut(duration: 0.2)) {
                    swipeOffset = shouldReveal ? -Self.swipeActionWidth : 0
                }
                isSwipeRevealed = shouldReveal
            }
    }

    private func closeSwipe() {
        isSwipeRevealed = false
        withAnimation(.easeOut(duration: 0.2)) {
            swipeOffset = 0
        }
    }

    /// An empty context menu still claims the long-press gesture, which would compete with
    /// Board View's drag-to-reorder, so only install it when there is something to show.
    @ViewBuilder
    private var contentWithContextMenu: some View {
        if hasContextMenuActions {
            gestureContent.contextMenu { menuContent }
        } else {
            gestureContent
        }
    }

    private var hasContextMenuActions: Bool {
        guard !isSelecting else { return false }
        return onDueDateAction != nil
            || onMoveToTop != nil
            || onMoveToBottom != nil
            || onMoveUp != nil
            || onMoveDown != nil
            || (onMoveToList != nil && !listSections.isEmpty)
            || onDelete != nil
    }

    @ViewBuilder
    private var menuContent: some View {
        if let onDueDateAction {
            Menu {
                // Schedule actions are context-aware: a task never gets an action that
                // would re-apply the schedule it already has.
                if !isScheduledForToday {
                    Button("Today") {
                        onDueDateAction(.today)
                    }
                }
                if !isScheduledForTomorrow {
                    Button("Tomorrow") {
                        onDueDateAction(.tomorrow)
                    }
                }
                Button("Choose a Date…") {
                    onDueDateAction(.custom)
                }
            } label: {
                Label("Reschedule", systemImage: "calendar")
            }
        }
        if onMoveToTop != nil || onMoveToBottom != nil || onMoveUp != nil || onMoveDown != nil {
            Divider()
        }
        if let moveTop = onMoveToTop {
            Button("Move to Top") {
                moveTop()
            }
        }
        if let moveBottom = onMoveToBottom {
            Button("Move to Bottom") {
                moveBottom()
            }
        }
        if let moveUp = onMoveUp {
            Button("Move Up") {
                moveUp()
            }
        }
        if let moveDown = onMoveDown {
            Button("Move Down") {
                moveDown()
            }
        }
        if let moveToList = onMoveToList, !listSections.isEmpty {
            Menu("Move to List") {
                ForEach(listSections) { section in
                    let lists = section.lists.filter { $0.persistentModelID != excludedListID }
                    if !lists.isEmpty {
                        Section(section.title ?? "") {
                            ForEach(lists) { list in
                                Button(list.name) {
                                    moveToList(list)
                                }
                            }
                        }
                    }
                }
            }
        }
        if let delete = onDelete {
            Divider()
            Button(role: .destructive) {
                delete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            if isSelecting {
                Button {
                    Haptics.selection()
                    onSelectToggle?()
                } label: {
                    SelectionCircle(isSelected: isSelected)
                }
                .buttonStyle(.plain)
                .disabled(onSelectToggle == nil)
                .accessibilityLabel(isSelected ? "Deselect" : "Select")
                .accessibilityIdentifier("task-select-toggle")
            } else {
                completionButton
            }

            // The open-row gesture lives on the text block only. A row-wide `onTapGesture`
            // competes with the completion button and swallows taps aimed at the circle, so
            // the two must not share a hit region.
            titleView
                .contentShape(Rectangle())
                .onTapGesture {
                    if isSelecting {
                        Haptics.selection()
                        onSelectToggle?()
                    } else {
                        Haptics.impact(.light)
                        onTap?()
                    }
                }

            Spacer(minLength: 0)

            if subtaskSummary.total > 0, let onToggleExpand {
                Button {
                    Haptics.impact(.light)
                    onToggleExpand()
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(AppFont.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.colors.textSecondary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse subtasks" : "Expand subtasks")
            }
        }
        .padding(.vertical, AppSpacing.rowVertical)
        .padding(.horizontal, AppSpacing.md)
    }

    @ViewBuilder
    private var titleView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(attributedTitle)
                .font(AppFont.body)
                .foregroundStyle(isCompletedVisualState ? AppTheme.colors.textSecondary : AppTheme.colors.textPrimary)
                .tint(isCompletedVisualState ? AppTheme.colors.textSecondary : AppTheme.colors.primaryAction)
                .strikethrough(isCompletedVisualState, color: AppTheme.colors.textSecondary)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .animation(.easeInOut(duration: 0.18), value: isCompletedVisualState)

            if !task.safeDescription.isEmpty {
                Text(task.safeDescription)
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppTheme.colors.textSecondary)
                    .lineLimit(4)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
            }

            if let metadataText {
                Text(metadataText)
                    .font(AppFont.footnote)
                    .foregroundStyle(isCompletedVisualState ? AppTheme.colors.textSecondary : (isOverdue ? AppTheme.colors.error : AppTheme.colors.textSecondary))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var attributedTitle: AttributedString {
        let raw = task.safeTitle
        var attributed = AttributedString(raw)
        let nsRange = NSRange(raw.startIndex..<raw.endIndex, in: raw)

        guard let detector = Self.cachedDetector else {
            return attributed
        }

        let matches = detector.matches(in: raw, options: [], range: nsRange)
        for match in matches {
            guard
                let url = match.url,
                let scheme = url.scheme?.lowercased(),
                scheme == "http" || scheme == "https",
                let range = Range(match.range, in: attributed)
            else {
                continue
            }
            attributed[range].link = url
        }

        return attributed
    }

    private var hasTime: Bool {
        guard let dueDate = task.dueDate else { return false }
        let components = Calendar.current.dateComponents([.hour, .minute], from: dueDate)
        return (components.hour != 0 || components.minute != 0)
    }

    private var timeText: String? {
        guard let dueDate = task.dueDate else { return nil }
        return Self.timeFormatter.string(from: dueDate)
    }

    private var dateText: String? {
        guard let dueDate = task.dueDate else { return nil }
        return Self.dueDateFormatter.string(from: dueDate)
    }

    private var groupDisplayName: String? {
        if let groupNameOverride {
            return groupNameOverride
        }
        guard showsGroupName else { return nil }
        if let group = task.reminderList?.group {
            let trimmed = group.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed == "Personal" || trimmed == "Home" { return "Personal" }
            if trimmed == "Work" { return "Work" }
            if !trimmed.isEmpty && trimmed != "Inbox" { return trimmed }
        }
        if let listName = task.reminderList?.name {
            let trimmed = listName.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed == "Work" { return "Work" }
            if trimmed == "Personal" || trimmed == "Home" { return "Personal" }
        }
        return nil
    }

    private var isOverdue: Bool {
        let now = Date()
        let calendar = Calendar.current
        guard let dueDate = task.dueDate else { return false }
        if isCompletedVisualState { return false }
        if hasTime {
            return dueDate < now
        } else {
            let dueStart = calendar.startOfDay(for: dueDate)
            let todayStart = calendar.startOfDay(for: now)
            return dueStart < todayStart
        }
    }

    private var listDisplayName: String? {
        guard showsListName else { return nil }
        let trimmed = task.reminderList?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private var metadataText: String? {
        var components: [String] = []

        if let listDisplayName {
            components.append(listDisplayName)
        }

        if let deferCount = task.deferCount, deferCount >= 2 {
            components.append("\(deferCount)x deferred")
        }

        if hasTime, let timeText {
            components.append(timeText)
        }

        if showsDueDate, let dateText {
            components.append(dateText)
        }

        if let groupDisplayName {
            components.append(groupDisplayName)
        }

        if !subtaskSummary.isEmpty {
            components.append("Subtasks \(subtaskSummary.displayText)")
        }

        if task.safeIsFlagged {
            components.append("Flagged")
        }

        if task.priority != .none {
            components.append(task.priority.title)
        }

        return components.isEmpty ? nil : components.joined(separator: "  ·  ")
    }

    private var completionButton: some View {
        Button {
            Haptics.impact(.light)
            animateChipTap()
            onToggleCompletion()
        } label: {
            ZStack {
                Circle()
                    .fill(isCompletedVisualState ? AppTheme.colors.tint.opacity(0.15) : .clear)
                    .frame(width: checkboxSize, height: checkboxSize)
                    .scaleEffect(isCompletedVisualState ? 1.09 : 1)
                    .animation(.easeInOut(duration: 0.18), value: isCompletedVisualState)

                if !isCompletedVisualState {
                    Circle()
                        .stroke(AppTheme.colors.tint, lineWidth: 1)
                        .frame(width: checkboxSize, height: checkboxSize)
                        .animation(.easeInOut(duration: 0.18), value: isCompletedVisualState)
                }

                Image(systemName: "checkmark")
                    .font(AppFont.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.tint)
                    .opacity(isCompletedVisualState ? 1 : 0)
                    .scaleEffect(isCompletedVisualState ? 1.0 : 0.85)
                    .animation(.easeInOut(duration: 0.14), value: isCompletedVisualState)
            }
            .scaleEffect(chipScale)
            .frame(width: checkboxSize, height: checkboxSize)
            .background(Color.clear.frame(width: 44, height: 44))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("task-complete-toggle")
        .accessibilityLabel(isCompletedVisualState ? "Mark active" : "Mark complete")
        .accessibilityHint(isCompletedVisualState ? "Reverts this task to pending" : "Marks this task as completed")
    }

    private func animateChipTap() {
        withAnimation(.easeOut(duration: 0.07)) {
            chipScale = 0.92
        }
        withAnimation(.spring(response: 0.12, dampingFraction: 0.7, blendDuration: 0)) {
            chipScale = 1.0
        }
    }

    private static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE, MMM d")
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private var isScheduledForToday: Bool {
        guard let dueDate = task.dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    private var isScheduledForTomorrow: Bool {
        guard let dueDate = task.dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }

}

extension TaskRowView {
    /// Shared wiring for task rows on Today, Agenda, Calendar, Work and Personal. Keeping
    /// this in the row component means one place owns completion haptics, swipe-to-delete,
    /// rescheduling and the open-task interaction for every surface.
    init(
        task: TaskItem,
        actions: TaskRowActions,
        showsDueDate: Bool,
        showsListName: Bool = true,
        enablesFallbackSwipe: Bool = false
    ) {
        self.init(
            task: task,
            isCompletedVisualState: task.isCompleted ?? false,
            onToggleCompletion: {
                Haptics.impact(.light)
                actions.toggleCompletion(task)
            },
            onDueDateAction: actions.reschedule.map { reschedule in
                { action in reschedule(task, action) }
            },
            onDelete: { actions.delete(task) },
            onTap: { actions.open(task) },
            showsDueDate: showsDueDate,
            showsListName: showsListName,
            enablesFallbackSwipe: enablesFallbackSwipe
        )
    }
}
