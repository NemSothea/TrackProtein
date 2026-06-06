import Foundation
import SwiftData

@Model
final class UserProfile {
    var weightKg: Double
    var goalTypeRaw: String
    var dailyTargetGrams: Double
    var createdAt: Date

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
