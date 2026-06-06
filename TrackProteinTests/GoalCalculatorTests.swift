import Testing
@testable import TrackProtein

struct GoalCalculatorTests {
    @Test func maintainTargetRoundsToNearestFive() {
        // 70 × 1.2 = 84 → 85
        #expect(GoalCalculator.dailyTarget(weightKg: 70, goal: .maintain) == 85)
    }

    @Test func buildMuscleTarget() {
        // 80 × 1.8 = 144 → 145
        #expect(GoalCalculator.dailyTarget(weightKg: 80, goal: .buildMuscle) == 145)
    }

    @Test func loseFatTarget() {
        // 100 × 2.0 = 200 (already a multiple of 5)
        #expect(GoalCalculator.dailyTarget(weightKg: 100, goal: .loseFat) == 200)
    }

    @Test func roundsDownWhenCloser() {
        // 56 × 1.8 = 100.8 → 100
        #expect(GoalCalculator.dailyTarget(weightKg: 56, goal: .buildMuscle) == 100)
    }

    @Test func targetIsAlwaysMultipleOfFive() {
        for weight in stride(from: 40.0, through: 150.0, by: 7.3) {
            for goal in GoalType.allCases {
                let target = GoalCalculator.dailyTarget(weightKg: weight, goal: goal)
                #expect(target.truncatingRemainder(dividingBy: 5) == 0)
            }
        }
    }
}
