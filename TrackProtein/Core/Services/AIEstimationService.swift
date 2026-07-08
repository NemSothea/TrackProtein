import Foundation

/// The structured estimate returned by the AI proxy (schema defined in proxy/worker.js).
struct AIEstimate: Decodable, Sendable {
    struct Item: Decodable, Sendable, Identifiable {
        let name: String
        let grams: Double

        var id: String { name }
    }

    let items: [Item]
    let totalGrams: Double
    let lowGrams: Double
    let highGrams: Double
    let confidence: String
    let notes: String?
    /// Display-only macro context from the on-device model (nil from the old proxy).
    /// The app tracks protein only — these are never logged.
    var fatGrams: Double?
    var carbGrams: Double?
    var calories: Double?
}

/// Talks to the Cloudflare Worker proxy — the Anthropic API key never ships in the app.
enum AIEstimationService {
    enum AIError: Error {
        case notConfigured
        case badResponse
    }

    /// Deploy proxy/worker.js first (see proxy/README.md), then set these.
    static let proxyURL = ""
    static let appSecret = ""

    static var isConfigured: Bool { !proxyURL.isEmpty }

    /// Estimate from a meal photo (JPEG data, ideally downscaled to ~1024px).
    static func estimate(imageData: Data) async throws -> AIEstimate {
        try await request(body: [
            "type": "photo",
            "image": imageData.base64EncodedString(),
            "mediaType": "image/jpeg",
        ])
    }

    /// Estimate from a natural-language description, e.g. "2 eggs and a shake".
    static func estimate(text: String) async throws -> AIEstimate {
        try await request(body: ["type": "text", "text": text])
    }

    private static func request(body: [String: String]) async throws -> AIEstimate {
        guard isConfigured, let url = URL(string: proxyURL) else {
            throw AIError.notConfigured
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !appSecret.isEmpty {
            request.setValue(appSecret, forHTTPHeaderField: "x-app-secret")
        }
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AIError.badResponse
        }
        return try JSONDecoder().decode(AIEstimate.self, from: data)
    }
}
