import Foundation
import Testing
@testable import TrackProtein

struct StreakCalculatorTests {
    private let calendar = Calendar.current
    private let goal: Double = 100
    /// Fixed reference "today" at 18:00 so tests are deterministic within a run.
    private var asOf: Date {
        calendar.startOfDay(for: .now).addingTimeInterval(18 * 3600)
    }

    /// An entry at midday `offset` days back from today.
    private func entry(daysAgo offset: Int, grams: Double) -> ProteinEntry {
        let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: asOf)) ?? asOf
        return ProteinEntry(grams: grams, date: day.addingTimeInterval(12 * 3600))
    }

    @Test func emptyEntriesGiveZeroStreak() {
        #expect(StreakCalculator.currentStreak(entries: [], goalGrams: goal, asOf: asOf) == 0)
    }

    @Test func todayMetCountsAsOne() {
        let entries = [entry(daysAgo: 0, grams: 120)]
        #expect(StreakCalculator.currentStreak(entries: entries, goalGrams: goal, asOf: asOf) == 1)
    }

    @Test func exactGoalCounts() {
        let entries = [entry(daysAgo: 0, grams: 100)]
        #expect(StreakCalculator.currentStreak(entries: entries, goalGrams: goal, asOf: asOf) == 1)
    }

    @Test func unfinishedTodayDoesNotBreakStreak() {
        let entries = [
            entry(daysAgo: 0, grams: 40),   // today, under goal — shouldn't break
            entry(daysAgo: 1, grams: 120),
            entry(daysAgo: 2, grams: 110),
        ]
        #expect(StreakCalculator.currentStreak(entries: entries, goalGrams: goal, asOf: asOf) == 2)
    }

    @Test func gapBreaksStreak() {
        let entries = [
            entry(daysAgo: 0, grams: 120),
            entry(daysAgo: 1, grams: 120),
            // day 2 missing
            entry(daysAgo: 3, grams: 120),
        ]
        #expect(StreakCalculator.currentStreak(entries: entries, goalGrams: goal, asOf: asOf) == 2)
    }

    @Test func multipleEntriesPerDaySumTowardGoal() {
        let entries = [
            entry(daysAgo: 0, grams: 60),
            entry(daysAgo: 0, grams: 50),   // 110 total today
        ]
        #expect(StreakCalculator.currentStreak(entries: entries, goalGrams: goal, asOf: asOf) == 1)
    }

    @Test func underGoalYesterdayGivesZero() {
        let entries = [
            entry(daysAgo: 0, grams: 40),
            entry(daysAgo: 1, grams: 40),
        ]
        #expect(StreakCalculator.currentStreak(entries: entries, goalGrams: goal, asOf: asOf) == 0)
    }
}
