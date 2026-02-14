//
//  TaskListView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI
import SwiftData

struct TaskListView: View {
    private enum CaptureMetrics {
        static let bottomInset: CGFloat = 10
        static let horizontalScreenInset: CGFloat = 16
        static let inputMinHeight: CGFloat = 54
        static let inputVerticalPadding: CGFloat = 15
        static let inputHorizontalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 16
        static let containerVerticalPadding: CGFloat = 8
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var captureSession = CaptureSessionState()
    @State private var newTaskTitle = ""
    @FocusState private var captureFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.colors.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    Group {
                    if tasks.isEmpty {
                        EmptyStateView(type: .noTasks)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(tasks) { task in
                                taskRow(task)
                            }
                        }
                    }
                    }
                    .padding(.horizontal, AppTheme.spacing.lg)
                    .padding(.top, AppTheme.spacing.md)
                    .padding(.bottom, AppTheme.spacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
                .animation(.easeInOut, value: tasks.count)
                .simultaneousGesture(
                    DragGesture().onChanged { _ in
                        captureSession.markScrolledBeforeTyping()
                    }
                )
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle("Tasks")
            .safeAreaInset(edge: .bottom) {
                captureBar
            }
            .onAppear {
                updateFocusIfNeeded()
            }
            .onChange(of: scenePhase) { phase in
                captureSession.handleScenePhase(phase)
                if phase == .active {
                    updateFocusIfNeeded()
                }
            }
            .onChange(of: captureFocused) { focused in
                if focused {
                    captureSession.recordFocused()
                } else if scenePhase == .active {
                    captureSession.markKeyboardDismissed()
                }
            }
            .onChange(of: newTaskTitle) { value in
                if hasTrailingNewline(value) {
                    newTaskTitle = value.trimmingTrailingNewlines()
                    submitFromKeyboard()
                    return
                }

                if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    captureSession.markTypedInSession()
                }
            }
        }
    }
    
    private func taskRow(_ task: TaskItem) -> some View {
        TaskRowView(task: task)
    }
    
    private func createTask(title: String) {
        let normalizedTitle = normalizedCaptureTitle(title)
        guard !normalizedTitle.isEmpty else { return }

        let task = TaskItem(taskTitle: normalizedTitle)
        modelContext.insert(task)
        captureSession.recordTaskAdded()
    }

    private var captureBar: some View {
        VStack(spacing: .zero) {
            ZStack(alignment: .topLeading) {
                if newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("What's on your mind?")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(AppTheme.colors.textDisabled)
                }

                TextField("", text: $newTaskTitle, axis: .vertical)
                    .submitLabel(.done)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppTheme.colors.textPrimary)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .multilineTextAlignment(.leading)
                    .focused($captureFocused)
                    .onSubmit {
                        submitFromKeyboard()
                    }
            }
            .padding(.vertical, CaptureMetrics.inputVerticalPadding)
            .padding(.horizontal, CaptureMetrics.inputHorizontalPadding)
            .frame(minHeight: CaptureMetrics.inputMinHeight)
            .background(AppTheme.colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: CaptureMetrics.cornerRadius)
                    .stroke(AppTheme.colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: CaptureMetrics.cornerRadius))
        }
        .padding(.vertical, CaptureMetrics.containerVerticalPadding)
        .padding(.horizontal, CaptureMetrics.horizontalScreenInset)
        .padding(.bottom, CaptureMetrics.bottomInset)
        .background(AppTheme.colors.appBackground)
    }

    private func updateFocusIfNeeded() {
        if captureSession.shouldAutoFocus(isListEmpty: tasks.isEmpty) {
            captureFocused = true
        }
    }

    private func submitFromKeyboard() {
        let normalizedTitle = normalizedCaptureTitle(newTaskTitle)
        guard !normalizedTitle.isEmpty else { return }

        createTask(title: normalizedTitle)
        newTaskTitle = ""
        captureFocused = true
    }

    private func normalizedCaptureTitle(_ rawTitle: String) -> String {
        let withSpacesForNewlines = rawTitle
            .components(separatedBy: .newlines)
            .joined(separator: " ")
        return withSpacesForNewlines.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func hasTrailingNewline(_ value: String) -> Bool {
        value.last?.isNewline == true
    }

}

private extension String {
    func trimmingTrailingNewlines() -> String {
        var result = self
        while result.last?.isNewline == true {
            result.removeLast()
        }
        return result
    }
}


#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedTaskList(into: container)
    return TaskListView()
        .modelContainer(container)
}

#Preview("Empty State") {
    TaskListView()
        .modelContainer(for: [TaskItem.self], inMemory: true)
}
