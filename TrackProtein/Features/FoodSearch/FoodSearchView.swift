import SwiftUI

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FoodSearchViewModel()
    @State private var selectedFood: FoodResult?

    var body: some View {
        NavigationStack {
            List {
                if viewModel.trimmedQuery.isEmpty, !viewModel.recentQueries.isEmpty {
                    Section("Recent") {
                        ForEach(viewModel.recentQueries, id: \.self) { recent in
                            Button {
                                viewModel.selectRecent(recent)
                            } label: {
                                Label(recent, systemImage: "clock.arrow.circlepath")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }

                if !viewModel.results.isEmpty {
                    Section("Results") {
                        ForEach(viewModel.results) { food in
                            resultRow(food)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search foods, e.g. chicken breast"
            )
            .overlay { overlayContent }
            .navigationTitle("Food Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $selectedFood) { food in
                PortionPickerView(food: food, source: .search) {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if viewModel.isLoading {
            ProgressView("Searching…")
        } else if let error = viewModel.errorMessage {
            ContentUnavailableView("Offline", systemImage: "wifi.slash", description: Text(error))
        } else if !viewModel.trimmedQuery.isEmpty, viewModel.trimmedQuery.count >= 2, viewModel.results.isEmpty {
            ContentUnavailableView.search(text: viewModel.trimmedQuery)
        } else if viewModel.trimmedQuery.isEmpty, viewModel.recentQueries.isEmpty {
            ContentUnavailableView(
                "Find any food",
                systemImage: "magnifyingglass",
                description: Text("Results from USDA and Open Food Facts, with protein per 100 g.")
            )
        }
    }

    private func resultRow(_ food: FoodResult) -> some View {
        Button { selectedFood = food } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .font(.body)
                        .lineLimit(2)
                    Text([food.brand, food.source.rawValue].compactMap(\.self).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let per100 = food.proteinPer100g {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(Int(per100.rounded()))g")
                            .font(.headline)
                            .foregroundStyle(Color.proteinOrange)
                        Text("per 100g")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if let perServing = food.proteinPerServing {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(Int(perServing.rounded()))g")
                            .font(.headline)
                            .foregroundStyle(Color.proteinOrange)
                        Text("per serving")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FoodSearchView()
        .modelContainer(for: [UserProfile.self, ProteinEntry.self, FavoriteFood.self], inMemory: true)
}
