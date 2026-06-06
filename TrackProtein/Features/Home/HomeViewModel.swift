import Foundation
import Observation
import SwiftData

@Observable
final class HomeViewModel {
    var showQuickAdd = false
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

    func logFavorite(_ favorite: FavoriteFood, context: ModelContext) {
        let entry = ProteinEntry(grams: favorite.grams, label: favorite.name, source: .favorite)
        context.insert(entry)
        favorite.lastUsed = .now
        WidgetRefresher.refresh()
    }

    func delete(_ entry: ProteinEntry, context: ModelContext) {
        context.delete(entry)
        WidgetRefresher.refresh()
    }
}
