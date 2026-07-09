//
//  TaskRowView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI
import SwiftData

struct TaskRowView: View, Equatable {
    let task: TaskItem
    var isCompletedVisualState: Bool = false
    var onToggleCompletion: () -> Void
    var onMoveToToday: (() -> Void)? = nil
    var onMoveToTomorrow: (() -> Void)? = nil
    var onMoveToLater: (() -> Void)? = nil
    var onSchedule: (() -> Void)? = nil
    var onMoveToList: ((ReminderList) -> Void)? = nil
    var listSections: [ListSection] = []
    var onDelete: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    var showsDueDate: Bool = false
    var showsListName: Bool = true
    var nestingDepth: Int = 0
    var subtaskCount: Int = 0
    var isCollapsed: Bool = false
    var onToggleCollapse: (() -> Void)? = nil

    private static let cachedDetector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()

    @State private var chipScale: CGFloat = 1

    static func == (lhs: TaskRowView, rhs: TaskRowView) -> Bool {
        lhs.task.persistentModelID == rhs.task.persistentModelID
            && lhs.isCompletedVisualState == rhs.isCompletedVisualState
            && lhs.subtaskCount == rhs.subtaskCount
            && lhs.isCollapsed == rhs.isCollapsed
            && lhs.nestingDepth == rhs.nestingDepth
    }
    
    var body: some View {
        rowContent
            .contextMenu {
                if let moveToday = onMoveToToday {
                    Button("Today") {
                        moveToday()
                    }
                }
                if let moveTomorrow = onMoveToTomorrow {
                    Button("Tomorrow") {
                        moveTomorrow()
                    }
                }
                if let moveLater = onMoveToLater {
                    Button("Later") {
                        moveLater()
                    }
                }
                if let schedule = onSchedule {
                    Button("Schedule") {
                        schedule()
                    }
                }
                if let moveToList = onMoveToList, !listSections.isEmpty {
                    Menu("Move to List") {
                        ForEach(listSections) { section in
                            Section(section.title ?? "") {
                                ForEach(section.lists) { list in
                                    Button(list.name) {
                                        moveToList(list)
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
            .onTapGesture {
                onTap?()
            }
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 12) {
            if subtaskCount > 0 {
                chevronButton
            }

            completionButton

            titleView
        }
        .padding(.leading, CGFloat(nestingDepth) * 20)
        .contentShape(Rectangle())
        .padding(.vertical, 10)
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
                    .strikethrough(isCompletedVisualState, color: AppTheme.colors.textSecondary)
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
                    .foregroundStyle(isCompletedVisualState ? AppTheme.colors.textSecondary : AppTheme.colors.textSecondary)
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

    private var metadataText: String? {
        var components: [String] = []

        if hasTime, let timeText {
            components.append(timeText)
        }

        if showsDueDate, let dateText {
            components.append(dateText)
        }

        if showsListName {
            components.append(task.listName)
        }

        if subtaskCount > 0 {
            components.append("\(subtaskCount)")
        }

        return components.isEmpty ? nil : components.joined(separator: "  ·  ")
    }

    private var chevronButton: some View {
        Button {
            onToggleCollapse?()
        } label: {
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(AppTheme.colors.textSecondary)
                .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("subtask-chevron")
    }

    private var completionButton: some View {
        Button {
            animateChipTap()
            onToggleCompletion()
        } label: {
            ZStack {
                Circle()
                    .stroke(isCompletedVisualState ? AppTheme.colors.primaryAction : AppTheme.colors.border, lineWidth: 1.5)
                    .background(
                        Circle()
                            .fill(isCompletedVisualState ? AppTheme.colors.primaryAction : AppTheme.colors.surface)
                    )
                    .frame(width: 20, height: 20)
                    .animation(.easeInOut(duration: 0.18), value: isCompletedVisualState)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textOnPrimaryAction)
                    .opacity(isCompletedVisualState ? 1 : 0)
                    .scaleEffect(isCompletedVisualState ? 1.0 : 0.85)
                    .animation(.easeInOut(duration: 0.14), value: isCompletedVisualState)
            }
            .scaleEffect(chipScale)
        }
        .buttonStyle(.plain)
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
}
