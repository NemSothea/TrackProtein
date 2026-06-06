import Foundation
import Observation

@MainActor
@Observable
final class FoodSearchViewModel {
    var query = "" {
        didSet { scheduleSearch() }
    }
    var results: [FoodResult] = []
    var isLoading = false
    var errorMessage: String?
    private(set) var recentQueries: [String]

    private var cache: [String: [FoodResult]] = [:]
    private var searchTask: Task<Void, Never>?

    private static let recentsKey = "recentFoodSearches"
    private static let maxRecents = 8

    init() {
        recentQueries = UserDefaults.standard.stringArray(forKey: Self.recentsKey) ?? []
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func selectRecent(_ recent: String) {
        query = recent
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        errorMessage = nil

        let term = trimmedQuery
        guard term.count >= 2 else {
            results = []
            isLoading = false
            return
        }
        if let cached = cache[term.lowercased()] {
            results = cached
            isLoading = false
            return
        }

        searchTask = Task {
            // Debounce typing.
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            isLoading = true
            defer { isLoading = false }
            do {
                let found = try await FoodSearchService.search(term)
                guard !Task.isCancelled else { return }
                cache[term.lowercased()] = found
                results = found
                if !found.isEmpty { addRecent(term) }
            } catch {
                guard !Task.isCancelled else { return }
                results = []
                errorMessage = "Couldn't reach the food databases. Check your connection."
            }
        }
    }

    private func addRecent(_ term: String) {
        var recents = recentQueries.filter { $0.lowercased() != term.lowercased() }
        recents.insert(term, at: 0)
        recentQueries = Array(recents.prefix(Self.maxRecents))
        UserDefaults.standard.set(recentQueries, forKey: Self.recentsKey)
    }
}
