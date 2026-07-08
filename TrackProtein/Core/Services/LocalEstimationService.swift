import CoreML
import UIKit

/// On-device protein estimation from a meal photo — MobileNetV3 + quantile head trained
/// on Nutrition5k (see ml/PLAN-ML.md), shipped as ProteinEstimator.mlpackage. Replaces the
/// Claude proxy: fully offline, private, zero per-request cost. Produces the same
/// `AIEstimate` the proxy did; `items` is always empty (no per-item breakdown in v1).
enum LocalEstimationService {
    enum EstimationError: Error {
        case modelMissing
        case badImage
        case badOutput
    }

    /// Preprocessing must match ml/export_coreml.py's eval_crop: shorter side → 257 px,
    /// then a 224×224 center crop.
    private static let cropSide: CGFloat = 224
    private static let shorterSideTarget: CGFloat = 257

    /// Loaded on first estimate, not at launch. The mlpackage is bundled only with the app
    /// target — in the widget extension this resolves to `.failure(modelMissing)`, which is
    /// fine because widgets never estimate.
    private static let model: Result<MLModel, Error> = {
        guard let url = Bundle.main.url(forResource: "ProteinEstimator", withExtension: "mlmodelc") else {
            return .failure(EstimationError.modelMissing)
        }
        return Result { try MLModel(contentsOf: url) }
    }()

    /// Estimate protein grams from a meal photo. Quantile outputs (q10/q50/q90, conformally
    /// calibrated in the model graph) map to low/total/high grams.
    static func estimate(image: UIImage) async throws -> AIEstimate {
        try await Task.detached(priority: .userInitiated) {
            let model = try Self.model.get()
            guard let input = Self.modelInput(from: image) else {
                throw EstimationError.badImage
            }
            guard let constraint = model.modelDescription
                .inputDescriptionsByName["image"]?.imageConstraint else {
                throw EstimationError.badOutput
            }
            let imageValue = try MLFeatureValue(cgImage: input, constraint: constraint)
            let features = try MLDictionaryFeatureProvider(dictionary: ["image": imageValue])
            let output = try model.prediction(from: features)
            guard let q = output.featureValue(for: "quantiles")?.multiArrayValue, q.count == 3 else {
                throw EstimationError.badOutput
            }
            let low = max(q[0].doubleValue, 0)
            let total = max(q[1].doubleValue, 0)
            let high = max(q[2].doubleValue, low)
            // (fat g, carb g, kcal) — display-only context, never logged.
            let macros = output.featureValue(for: "macros")?.multiArrayValue
                .flatMap { $0.count == 3 ? $0 : nil }
            return AIEstimate(
                items: [],
                totalGrams: total,
                lowGrams: low,
                highGrams: high,
                confidence: Self.confidence(intervalWidth: high - low),
                notes: nil,
                fatGrams: macros.map { max($0[0].doubleValue, 0) },
                carbGrams: macros.map { max($0[1].doubleValue, 0) },
                calories: macros.map { max($0[2].doubleValue, 0) }
            )
        }.value
    }

    /// Narrow interval → accurate estimate (verified on the test set: narrowest third of
    /// intervals has ~0.7 g MAE vs ~10 g for the widest third). Thresholds ≈ width terciles.
    private static func confidence(intervalWidth: Double) -> String {
        switch intervalWidth {
        case ..<12: "high"
        case ..<24: "medium"
        default: "low"
        }
    }

    private static func modelInput(from image: UIImage) -> CGImage? {
        let shorterSide = min(image.size.width, image.size.height)
        guard shorterSide > 0 else { return nil }
        let scale = shorterSideTarget / shorterSide
        let scaled = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let cropped = UIGraphicsImageRenderer(
            size: CGSize(width: cropSide, height: cropSide), format: format
        ).image { _ in
            image.draw(in: CGRect(
                x: (cropSide - scaled.width) / 2,
                y: (cropSide - scaled.height) / 2,
                width: scaled.width,
                height: scaled.height
            ))
        }
        return cropped.cgImage
    }
}
