//
//  TaskListView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var captureSession = CaptureSessionState()
    @State private var newTaskTitle = ""
    @FocusState private var captureFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.colors.background
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
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let task = TaskItem(taskTitle: trimmedTitle)
        modelContext.insert(task)
        captureSession.recordTaskAdded()
    }

    private var captureBar: some View {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(spacing: AppTheme.spacing.sm) {
            ZStack {
                TextField("Capture a task...", text: $newTaskTitle, axis: .vertical)
                    .font(AppTheme.fonts.body)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .multilineTextAlignment(.leading)
                    .focused($captureFocused)
                    .padding(.vertical, AppTheme.spacing.md)
                    .padding(.leading, AppTheme.spacing.sm)
                    .padding(.trailing, AppTheme.spacing.xl * 2.2)
                    .background(AppTheme.colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.medium))
                    .overlay(alignment: .bottomTrailing) {
                        simpleAddButton(isDisabled: trimmedTitle.isEmpty)
                            .padding(.trailing, AppTheme.spacing.sm)
                            .padding(.bottom, AppTheme.spacing.xs)
                    }
            }
        }
        .padding(.horizontal, AppTheme.spacing.md)
        .padding(.vertical, AppTheme.spacing.md)
        .background(AppTheme.colors.background)
    }

    private func updateFocusIfNeeded() {
        if captureSession.shouldAutoFocus(isListEmpty: tasks.isEmpty) {
            captureFocused = true
        }
    }

}

private extension TaskListView {
    func simpleAddButton(isDisabled: Bool) -> some View {
        Button {
            createTask(title: newTaskTitle)
            newTaskTitle = ""
            captureFocused = true
        } label: {
            Text("Add")
                .font(AppTheme.fonts.body.weight(.semibold))
                .foregroundStyle(isDisabled ? AppTheme.colors.secondaryText : AppTheme.colors.primary)
                .padding(.horizontal, AppTheme.spacing.xs)
                .padding(.vertical, AppTheme.spacing.xxs)
                .frame(minWidth: 40, minHeight: 40, alignment: .center)
                .contentShape(Rectangle())
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
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
