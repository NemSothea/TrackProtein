import Foundation
import Observation

@MainActor
@Observable
final class BarcodeScanViewModel {
    var isScanning = true
    var isLookingUp = false
    var foundFood: FoodResult?
    var notFoundCode: String?

    func handleScan(_ code: String) {
        guard !isLookingUp, foundFood == nil, notFoundCode == nil else { return }
        isScanning = false
        isLookingUp = true

        Task {
            defer { isLookingUp = false }
            let result = try? await FoodSearchService.product(barcode: code)
            if let result, result.hasProteinData {
                foundFood = result
            } else {
                notFoundCode = code
            }
        }
    }

    func rescan() {
        foundFood = nil
        notFoundCode = nil
        isScanning = true
    }
}
