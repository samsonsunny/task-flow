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

    private static let cachedDetector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()

    @State private var chipScale: CGFloat = 1

    static func == (lhs: TaskRowView, rhs: TaskRowView) -> Bool {
        lhs.task.persistentModelID == rhs.task.persistentModelID
            && lhs.isCompletedVisualState == rhs.isCompletedVisualState
            && lhs.subtaskSummary == rhs.subtaskSummary
            && lhs.isSelecting == rhs.isSelecting
            && lhs.isSelected == rhs.isSelected
    }
    
    var body: some View {
        rowContent
            .background(
                isSelected ? AppTheme.colors.primaryAction.opacity(0.12) : Color.clear
            )
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
            .contextMenu {
                if !isSelecting {
                    if let onDueDateAction {
                        Menu("Deadline") {
                            if activeDueDateItem == .none {
                                Button {
                                    onDueDateAction(.none)
                                } label: {
                                    Label("None", systemImage: "checkmark")
                                }
                            } else {
                                Button("None") {
                                    onDueDateAction(.none)
                                }
                            }
                            Divider()
                            presetButton("Today", action: .today)
                            presetButton("Tomorrow", action: .tomorrow)
                            presetButton("This Weekend", action: .thisWeekend)
                            presetButton("Next Week", action: .nextWeek)
                            presetButton("Custom…", action: .custom)
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
            }
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 14) {
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.colors.textSecondary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse subtasks" : "Expand subtasks")
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.colors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.colors.textTertiary.opacity(0.12), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var titleView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(attributedTitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(isCompletedVisualState ? AppTheme.colors.textSecondary : AppTheme.colors.textPrimary)
                    .tint(isCompletedVisualState ? AppTheme.colors.textSecondary : AppTheme.colors.primaryAction)
                    .opacity(isCompletedVisualState ? 0.82 : 1.0)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .animation(.easeInOut(duration: 0.18), value: isCompletedVisualState)
            }

            if !task.safeDescription.isEmpty {
            Text(task.safeDescription)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(isCompletedVisualState ? AppTheme.colors.textSecondary : AppTheme.colors.textSecondary)
                .opacity(isCompletedVisualState ? 0.82 : 1.0)
                .lineLimit(4)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
            }

            if let metadataText {
                Text(metadataText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(isCompletedVisualState ? AppTheme.colors.textSecondary : (isOverdue ? AppTheme.colors.error : AppTheme.colors.textSecondary))
                    .opacity(isCompletedVisualState ? 0.82 : 1.0)
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

    private var metadataText: String? {
        var components: [String] = []

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

        // List name removed

        if !subtaskSummary.isEmpty {
            components.append(subtaskSummary.displayText)
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
                    .frame(width: 22, height: 22)
                    .animation(.easeInOut(duration: 0.18), value: isCompletedVisualState)

                if !isCompletedVisualState {
                    Circle()
                        .stroke(AppTheme.colors.textTertiary, lineWidth: 1.2)
                        .frame(width: 22, height: 22)
                        .animation(.easeInOut(duration: 0.18), value: isCompletedVisualState)
                }

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.colors.tint)
                    .opacity(isCompletedVisualState ? 1 : 0)
                    .scaleEffect(isCompletedVisualState ? 1.0 : 0.85)
                    .animation(.easeInOut(duration: 0.14), value: isCompletedVisualState)
            }
            .scaleEffect(chipScale)
            .frame(width: 22, height: 22)
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

    private var activeDueDateItem: DueDateAction? {
        guard let dueDate = task.dueDate else { return .none }
        let calendar = Calendar.current
        let now = Date()
        let taskDay = calendar.startOfDay(for: dueDate)
        let candidates: [(DueDateAction, Date)] = [
            (.today, calendar.startOfDay(for: now)),
            (.tomorrow, calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!),
            (.thisWeekend, ReminderSegmentViewModel.nextSaturday(from: now)),
            (.nextWeek, ReminderSegmentViewModel.nextMonday(from: now)),
        ]
        if let match = candidates.first(where: { calendar.isDate(taskDay, inSameDayAs: $0.1) }) {
            return match.0
        }
        return .custom
    }

    private func presetButton(_ title: String, action: DueDateAction) -> some View {
        Button {
            onDueDateAction?(action)
        } label: {
            if activeDueDateItem == action {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }
}
