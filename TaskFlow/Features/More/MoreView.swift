import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        SearchView()
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .listRowSeparator(.hidden)
                } header: {
                    EditorialSectionHeader(title: "Find", subtitle: "Search across Work and Home")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        EditorialStyle.eyebrow("Wednesday Calendar")
                        Text("Work and Home, in one calm system.")
                            .font(.title3.weight(.semibold))
                        Text("Your lists stay in their domain. Today brings together what needs you now.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .listRowSeparator(.hidden)
                } header: {
                    EditorialSectionHeader(title: "About", subtitle: "Designed around focus")
                }
            }
            .listStyle(.plain)
            .navigationTitle("More")
        }
    }
}
