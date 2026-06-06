import Foundation
import SwiftData

// All properties have defaults — required for CloudKit sync compatibility (enabled at launch).
@Model
final class UserProfile {
    var weightKg: Double = 70
    var goalTypeRaw: String = GoalType.maintain.rawValue
    var dailyTargetGrams: Double = 100
    var createdAt: Date = Date.now

    var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw) ?? .maintain }
        set { goalTypeRaw = newValue.rawValue }
    }

    init(weightKg: Double, goalType: GoalType, dailyTargetGrams: Double, createdAt: Date = .now) {
        self.weightKg = weightKg
        self.goalTypeRaw = goalType.rawValue
        self.dailyTargetGrams = dailyTargetGrams
        self.createdAt = createdAt
    }
}
