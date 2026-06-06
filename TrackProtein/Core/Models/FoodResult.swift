import Foundation

/// A food found via search or barcode — not persisted; logging it creates a `ProteinEntry`.
struct FoodResult: Identifiable, Hashable, Sendable {
    enum Source: String, Sendable {
        case openFoodFacts = "Open Food Facts"
        case usda = "USDA"
    }

    let id: String
    let name: String
    let brand: String?
    /// Grams of protein per 100 g of this food.
    let proteinPer100g: Double?
    /// Grams of protein in one serving, when the source provides it.
    let proteinPerServing: Double?
    /// Human-readable serving description, e.g. "30 g" or "1 cup".
    let servingDescription: String?
    let source: Source

    /// Usable for logging only if we have some protein figure.
    var hasProteinData: Bool {
        proteinPer100g != nil || proteinPerServing != nil
    }
}
