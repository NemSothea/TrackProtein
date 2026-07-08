import Foundation
import Observation
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AILogViewModel {
    /// Raw photo as picked/snapped — kept so the user can re-frame it.
    var originalImage: UIImage?
    /// The square region the user framed; this is exactly what the model analyzes and what
    /// the preview shows. The model needs the food to fill the frame (see PhotoCropView).
    var framedImage: UIImage?
    var showCropper = false
    var photoItem: PhotosPickerItem? {
        didSet { loadPhoto() }
    }
    var showCamera = false

    var isLoading = false
    var errorMessage: String?
    var estimate: AIEstimate?
    /// User-adjustable grams, prefilled from the estimate — always editable before saving.
    var adjustedGrams: Double = 0

    var canEstimate: Bool { framedImage != nil }

    private func loadPhoto() {
        guard let photoItem else { return }
        Task {
            if let data = try? await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                setPhoto(image)
            }
        }
    }

    /// A freshly picked/snapped photo → open the cropper so the user frames the food first.
    func setPhoto(_ image: UIImage) {
        originalImage = image
        framedImage = nil
        estimate = nil
        errorMessage = nil
        adjustedGrams = 0
        showCropper = true
    }

    func applyCrop(_ framed: UIImage) {
        framedImage = framed
        estimate = nil
        adjustedGrams = 0
        showCropper = false
    }

    func recrop() {
        if originalImage != nil { showCropper = true }
    }

    func runEstimate() {
        guard let image = framedImage, !isLoading else { return }
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }
            do {
                let result = try await LocalEstimationService.estimate(image: image)
                estimate = result
                adjustedGrams = result.totalGrams.rounded()
            } catch {
                errorMessage = "Couldn't analyze that photo — try another one."
            }
        }
    }

    func log(context: ModelContext) {
        guard let estimate, adjustedGrams > 0 else { return }
        let label = estimate.items.prefix(3).map(\.name).joined(separator: ", ")
        context.insert(ProteinEntry(
            grams: adjustedGrams,
            label: label.isEmpty ? "AI Meal" : label,
            source: .ai
        ))
        WidgetRefresher.refresh()
    }

    func reset() {
        estimate = nil
        errorMessage = nil
        adjustedGrams = 0
    }
}
