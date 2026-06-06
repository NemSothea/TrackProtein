import Foundation
import SwiftData

/// A saved one-tap food preset, e.g. "Chicken Breast — 31g".
/// All properties have defaults — required for CloudKit sync compatibility (enabled at launch).
@Model
final class FavoriteFood {
    var name: String = ""
    var grams: Double = 0
    var sortOrder: Int = 0
    var lastUsed: Date = Date.now

    init(name: String, grams: Double, sortOrder: Int = 0, lastUsed: Date = .now) {
        self.name = name
        self.grams = grams
        self.sortOrder = sortOrder
        self.lastUsed = lastUsed
    }
}
