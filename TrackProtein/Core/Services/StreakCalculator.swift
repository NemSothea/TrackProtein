import Foundation

enum StreakCalculator {
    /// Consecutive days (ending today or yesterday) where the daily total met the goal.
    /// An unfinished today does not break the streak.
    static func currentStreak(
        entries: [ProteinEntry],
        goalGrams: Double,
        calendar: Calendar = .current,
        asOf: Date = .now
    ) -> Int {
        let totals = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.grams } }

        var day = calendar.startOfDay(for: asOf)
        var streak = 0
        if (totals[day] ?? 0) >= goalGrams {
            streak += 1
        }
        while let prev = calendar.date(byAdding: .day, value: -1, to: day) {
            day = prev
            if (totals[day] ?? 0) >= goalGrams {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}
