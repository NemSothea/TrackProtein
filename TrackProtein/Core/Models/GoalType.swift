import Foundation

/// The user's training/health goal — drives the recommended protein target.
enum GoalType: String, CaseIterable, Codable, Identifiable {
    case maintain
    case buildMuscle
    case loseFat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .maintain: "Stay Healthy"
        case .buildMuscle: "Build Muscle"
        case .loseFat: "Lose Fat"
        }
    }

    var subtitle: String {
        switch self {
        case .maintain: "Maintain your current physique"
        case .buildMuscle: "Maximize muscle growth"
        case .loseFat: "Preserve muscle while cutting"
        }
    }

    var icon: String {
        switch self {
        case .maintain: "heart.fill"
        case .buildMuscle: "dumbbell.fill"
        case .loseFat: "flame.fill"
        }
    }

    /// Recommended protein intake in grams per kg of body weight.
    var gramsPerKg: Double {
        switch self {
        case .maintain: 1.2
        case .buildMuscle: 1.8
        case .loseFat: 2.0
        }
    }
}
