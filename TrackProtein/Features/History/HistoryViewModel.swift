import Foundation
import Observation

struct DaySummary: Identifiable {
    let date: Date
    let total: Double
    let entries: [ProteinEntry]

    var id: Date { date }
}

@Observable
final class HistoryViewModel {
    var selectedDay: DaySummary?

    /// Groups all entries into per-day summaries, newest first.
    func summaries(from entries: [ProteinEntry], calendar: Calendar = .current) -> [DaySummary] {
        Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
            .map { date, dayEntries in
                DaySummary(
                    date: date,
                    total: dayEntries.reduce(0) { $0 + $1.grams },
                    entries: dayEntries.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.date > $1.date }
    }
}
