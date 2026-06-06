import Foundation
import Observation
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AILogViewModel {
    enum Mode: String, CaseIterable {
        case photo = "Photo"
        case describe = "Describe"
    }

    var mode: Mode = .photo
    var selectedImage: UIImage?
    var photoItem: PhotosPickerItem? {
        didSet { loadPhoto() }
    }
    var textInput = ""
    var showCamera = false

    var isLoading = false
    var errorMessage: String?
    var estimate: AIEstimate?
    /// User-adjustable grams, prefilled from the estimate — always editable before saving.
    var adjustedGrams: Double = 0

    var canEstimate: Bool {
        switch mode {
        case .photo: selectedImage != nil
        case .describe: !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func loadPhoto() {
        guard let photoItem else { return }
        Task {
            if let data = try? await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                estimate = nil
            }
        }
    }

    func runEstimate() {
        guard canEstimate, !isLoading else { return }
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }
            do {
                let result: AIEstimate
                switch mode {
                case .photo:
                    guard let jpeg = selectedImage?.downscaled(maxDimension: 1024)
                        .jpegData(compressionQuality: 0.7) else {
                        errorMessage = "Couldn't process that photo — try another one."
                        return
                    }
                    result = try await AIEstimationService.estimate(imageData: jpeg)
                case .describe:
                    result = try await AIEstimationService.estimate(text: textInput)
                }
                estimate = result
                adjustedGrams = result.totalGrams.rounded()
            } catch AIEstimationService.AIError.notConfigured {
                errorMessage = "AI logging isn't set up yet. Deploy the proxy (proxy/README.md) and set the URL in AIEstimationService."
            } catch {
                errorMessage = "Couldn't get an estimate. Check your connection and try again."
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

extension UIImage {
    /// Downscale so the longest edge is at most `maxDimension` — keeps AI request bodies small.
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
