import Foundation
import Observation
import SwiftData

@Observable
final class HomeViewModel {
    var showQuickAdd = false
    var showFoodSearch = false
    var showBarcodeScan = false
    var entryToEdit: ProteinEntry?

    func todayEntries(from entries: [ProteinEntry]) -> [ProteinEntry] {
        entries.filter { $0.date.isToday }
    }

    func todayTotal(from entries: [ProteinEntry]) -> Double {
        todayEntries(from: entries).reduce(0) { $0 + $1.grams }
    }

    func streak(entries: [ProteinEntry], goal: Double) -> Int {
        StreakCalculator.currentStreak(entries: entries, goalGrams: goal)
    }

    /// Favorites used around this time of day first, then most recent (F14).
    func orderedFavorites(_ favorites: [FavoriteFood], now: Date = .now) -> [FavoriteFood] {
        let currentHour = Calendar.current.component(.hour, from: now)
        return favorites.sorted { a, b in
            let distanceA = hourDistance(a.lastUsedHour, currentHour)
            let distanceB = hourDistance(b.lastUsedHour, currentHour)
            if distanceA != distanceB { return distanceA < distanceB }
            return a.lastUsed > b.lastUsed
        }
    }

    /// Circular distance between two hours of day (23 and 1 are 2 apart, not 22).
    private func hourDistance(_ a: Int, _ b: Int) -> Int {
        let diff = abs(a - b)
        return min(diff, 24 - diff)
    }

    func logFavorite(_ favorite: FavoriteFood, context: ModelContext) {
        let entry = ProteinEntry(grams: favorite.grams, label: favorite.name, source: .favorite)
        context.insert(entry)
        favorite.lastUsed = .now
        favorite.lastUsedHour = Calendar.current.component(.hour, from: .now)
        WidgetRefresher.refresh()
    }

    func delete(_ entry: ProteinEntry, context: ModelContext) {
        context.delete(entry)
        WidgetRefresher.refresh()
    }
}
