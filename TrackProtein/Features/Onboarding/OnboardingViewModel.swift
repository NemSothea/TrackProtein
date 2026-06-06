import Foundation
import Observation

@Observable
final class OnboardingViewModel {
    var step = 0
    var weightKg: Double = 70
    var goalType: GoalType = .buildMuscle
    /// Set when the user manually adjusts the recommended target.
    var customTarget: Double?

    var recommendedTarget: Double {
        GoalCalculator.dailyTarget(weightKg: weightKg, goal: goalType)
    }

    var finalTarget: Double {
        customTarget ?? recommendedTarget
    }

    func adjustTarget(by delta: Double) {
        customTarget = max(30, min(400, finalTarget + delta))
    }

    func makeProfile() -> UserProfile {
        UserProfile(weightKg: weightKg, goalType: goalType, dailyTargetGrams: finalTarget)
    }

    /// Starter presets so the first log is one tap away.
    func makeStarterFavorites() -> [FavoriteFood] {
        [
            FavoriteFood(name: "Protein Shake", grams: 25, sortOrder: 0),
            FavoriteFood(name: "Chicken Breast", grams: 31, sortOrder: 1),
            FavoriteFood(name: "3 Eggs", grams: 18, sortOrder: 2),
        ]
    }
}
