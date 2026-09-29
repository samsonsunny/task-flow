import SwiftUI
import SwiftData

struct ListPickerView: View {
    let allLists: [ReminderList]
    let selectedListID: ReminderList.ID?
    let onSelect: (ReminderList.ID) -> Void

    @State private var searchText = ""

    private var sections: [ListSection] {
        buildListSections(from: allLists)
    }

    private var filteredSections: [ListSection] {
        guard !searchText.isEmpty else { return sections }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return sections.compactMap { section in
            let matching = section.lists.filter { $0.name.lowercased().contains(query) }
            guard !matching.isEmpty else { return nil }
            return ListSection(id: section.id, title: section.title, lists: matching)
        }
    }

    var body: some View {
        List {
            if filteredSections.isEmpty {
                emptyState
            } else {
                ForEach(filteredSections) { section in
                    sectionContent(section)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle("Choose List")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search lists")
    }

    @ViewBuilder
    private func sectionContent(_ section: ListSection) -> some View {
        if let title = section.title {
            Section(title) {
                listRows(for: section.lists)
            }
        } else {
            Section {
                listRows(for: section.lists)
            }
        }
    }

    private func listRows(for lists: [ReminderList]) -> some View {
        ForEach(lists) { list in
            Button {
                onSelect(list.persistentModelID)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: list.isBucket ? "tray" : "list.bullet")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.colors.textSecondary)
                        .frame(width: 24)

                    Text(rowTitle(for: list))
                        .font(.system(size: 17))
                        .foregroundStyle(AppTheme.colors.textPrimary)

                    Spacer()

                    if list.persistentModelID == selectedListID {
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppTheme.colors.primaryAction)
                    }
                }
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    private func rowTitle(for list: ReminderList) -> String {
        if list.isBucket, let group = list.group {
            return "\(group.name) · \(list.name)"
        }
        return list.name
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No lists found")
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textPrimary)
            Text("Try a different search term.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
    }
}
