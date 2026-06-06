import SwiftUI
import SwiftData

struct HomeView: View {
    let profile: UserProfile
    @Binding var quickAddRequest: Bool

    @Environment(\.modelContext) private var context
    @Query(sort: \ProteinEntry.date, order: .reverse) private var entries: [ProteinEntry]
    @Query(sort: \FavoriteFood.lastUsed, order: .reverse) private var favorites: [FavoriteFood]
    @State private var viewModel = HomeViewModel()

    private var todayEntries: [ProteinEntry] { viewModel.todayEntries(from: entries) }
    private var todayTotal: Double { viewModel.todayTotal(from: entries) }
    private var streak: Int { viewModel.streak(entries: entries, goal: profile.dailyTargetGrams) }

    var body: some View {
        NavigationStack {
            List {
                ringSection
                favoritesSection
                todaySection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { viewModel.showQuickAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.proteinOrange)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showQuickAdd) {
                QuickAddView()
            }
            .sheet(item: $viewModel.entryToEdit) { entry in
                QuickAddView(entry: entry)
            }
            .onChange(of: quickAddRequest) { _, requested in
                if requested {
                    viewModel.showQuickAdd = true
                    quickAddRequest = false
                }
            }
        }
    }

    // MARK: - Sections

    private var ringSection: some View {
        Section {
            VStack(spacing: 12) {
                ProgressRingView(consumed: todayTotal, target: profile.dailyTargetGrams)
                if streak > 0 {
                    Label("\(streak) day streak", systemImage: "flame.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.proteinOrange))
                }
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var favoritesSection: some View {
        if !favorites.isEmpty {
            Section("Favorites") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(favorites) { favorite in
                            favoriteChip(favorite)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
    }

    private func favoriteChip(_ favorite: FavoriteFood) -> some View {
        Button {
            withAnimation { viewModel.logFavorite(favorite, context: context) }
        } label: {
            VStack(spacing: 2) {
                Text(favorite.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(Int(favorite.grams.rounded()))g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                context.delete(favorite)
            } label: {
                Label("Delete Favorite", systemImage: "trash")
            }
        }
    }

    private var todaySection: some View {
        Section("Logged today") {
            if todayEntries.isEmpty {
                Text("Nothing logged yet — tap a favorite or hit +")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(todayEntries) { entry in
                    entryRow(entry)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.delete(todayEntries[index], context: context)
                    }
                }
            }
        }
    }

    private func entryRow(_ entry: ProteinEntry) -> some View {
        Button { viewModel.entryToEdit = entry } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.label?.isEmpty == false ? entry.label! : "Protein")
                        .font(.body)
                    Text(entry.date, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(entry.grams.rounded()))g")
                    .font(.headline)
                    .foregroundStyle(Color.proteinOrange)
            }
        }
        .buttonStyle(.plain)
    }
}
