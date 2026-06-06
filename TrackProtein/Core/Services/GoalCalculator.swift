import Foundation

enum GoalCalculator {
    /// Daily protein target in grams, rounded to the nearest 5 g.
    static func dailyTarget(weightKg: Double, goal: GoalType) -> Double {
        let raw = weightKg * goal.gramsPerKg
        return (raw / 5).rounded() * 5
    }
}
