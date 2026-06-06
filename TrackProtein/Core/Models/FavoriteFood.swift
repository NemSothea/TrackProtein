import Foundation
import SwiftData

/// A saved one-tap food preset, e.g. "Chicken Breast — 31g".
@Model
final class FavoriteFood {
    var name: String
    var grams: Double
    var sortOrder: Int
    var lastUsed: Date

    init(name: String, grams: Double, sortOrder: Int = 0, lastUsed: Date = .now) {
        self.name = name
        self.grams = grams
        self.sortOrder = sortOrder
        self.lastUsed = lastUsed
    }
}
