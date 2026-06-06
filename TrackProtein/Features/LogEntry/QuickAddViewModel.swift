import Foundation
import Observation
import SwiftData

@Observable
final class QuickAddViewModel {
    var gramsText = ""
    var label = ""
    var date: Date = .now
    var saveAsFavorite = false

    private let editingEntry: ProteinEntry?

    var isEditing: Bool { editingEntry != nil }

    var grams: Double? {
        Double(gramsText.replacingOccurrences(of: ",", with: "."))
    }

    var isValid: Bool {
        (grams ?? 0) > 0
    }

    init(entry: ProteinEntry? = nil, presetDate: Date? = nil) {
        self.editingEntry = entry
        if let entry {
            gramsText = String(Int(entry.grams.rounded()))
            label = entry.label ?? ""
            date = entry.date
        } else if let presetDate {
            // Never preset into the future (e.g. "noon" on today's row before noon).
            date = min(presetDate, .now)
        }
    }

    func addQuickAmount(_ amount: Double) {
        let current = grams ?? 0
        gramsText = String(Int((current + amount).rounded()))
    }

    func save(context: ModelContext) {
        guard let grams else { return }
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)

        if let entry = editingEntry {
            entry.grams = grams
            entry.label = trimmedLabel.isEmpty ? nil : trimmedLabel
            entry.date = date
        } else {
            let entry = ProteinEntry(
                grams: grams,
                label: trimmedLabel.isEmpty ? nil : trimmedLabel,
                date: date,
                source: .manual
            )
            context.insert(entry)
        }

        if saveAsFavorite, !trimmedLabel.isEmpty {
            context.insert(FavoriteFood(name: trimmedLabel, grams: grams))
        }

        WidgetRefresher.refresh()
    }
}
