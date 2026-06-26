import SwiftUI
import SwiftData

struct CompletedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var viewModel: CompletedViewModel?
    @State private var editingTask: TaskItem?

    var body: some View {
        List {
            if let vm = viewModel {
                if vm.recentCompletedTasks.isEmpty {
                    emptyState
                } else {
                    ForEach(vm.groupedTasks, id: \.0) { sectionTitle, tasks in
                        Section {
                            ForEach(tasks) { task in
                                completedTaskRow(task)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            viewModel?.delete(task)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            Text(sectionTitle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.colors.textSecondary)
                                .textCase(nil)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.colors.appBackground)
        .sheet(item: $editingTask) { task in
            ReminderEditorView(task: task)
        }
        .onAppear {
            viewModel = CompletedViewModel(modelContext: modelContext)
            viewModel?.update(tasks: allTasks)
        }
        .onChange(of: allTasks) { _, newTasks in
            viewModel?.update(tasks: newTasks)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No recently completed reminders")
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textPrimary)
            Text("Reminders you complete will appear here for 30 days.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private func completedTaskRow(_ task: TaskItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    viewModel?.uncomplete(task)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(AppTheme.colors.primaryAction, lineWidth: 1.5)
                        .background(Circle().fill(AppTheme.colors.primaryAction))
                        .frame(width: 20, height: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.colors.textOnPrimaryAction)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Un-complete task")

            VStack(alignment: .leading, spacing: 4) {
                Text(task.safeTitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppTheme.colors.textSecondary)
                    .strikethrough()
                    .opacity(0.82)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(CompletedViewModel.destinationLabel(for: task))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
        .onTapGesture {
            editingTask = task
        }
    }
}
