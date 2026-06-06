import Foundation

/// Searches Open Food Facts (primary, no key) and USDA FoodData Central (merged in when reachable).
enum FoodSearchService {
    /// Free demo key (rate-limited ~30 req/hr). For higher limits get a free key at
    /// https://fdc.nal.usda.gov/api-key-signup.html and replace.
    private static let usdaAPIKey = "DEMO_KEY"
    /// Open Food Facts asks API users to identify themselves.
    private static let userAgent = "TrackProtein/1.0 (iOS)"

    // MARK: - Public API

    /// Merged, deduped search across both sources. Sources fail independently —
    /// only throws if BOTH are unreachable.
    static func search(_ query: String) async throws -> [FoodResult] {
        async let offResults = try? searchOpenFoodFacts(query)
        async let usdaResults = try? searchUSDA(query)
        let off = await offResults
        let usda = await usdaResults

        if off == nil && usda == nil {
            throw URLError(.notConnectedToInternet)
        }

        var seen = Set<String>()
        return ((off ?? []) + (usda ?? []))
            .filter { $0.hasProteinData }
            .filter { seen.insert(dedupKey($0)).inserted }
    }

    /// Barcode lookup via Open Food Facts. Returns nil when the product is unknown.
    static func product(barcode: String) async throws -> FoodResult? {
        var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json")
        components?.queryItems = [URLQueryItem(name: "fields", value: "code,product_name,brands,serving_size,nutriments")]
        guard let url = components?.url else { throw URLError(.badURL) }

        let response: OFFProductResponse = try await fetch(url)
        guard response.status == 1, let product = response.product else { return nil }
        return result(from: product)
    }

    // MARK: - Open Food Facts

    private static func searchOpenFoodFacts(_ query: String) async throws -> [FoodResult] {
        var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")
        components?.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "20"),
            // NOTE: sort_by=unique_scans_n makes this endpoint return 503 — do not add it back.
            URLQueryItem(name: "fields", value: "code,product_name,brands,serving_size,nutriments"),
        ]
        guard let url = components?.url else { throw URLError(.badURL) }

        let response: OFFSearchResponse = try await fetch(url)
        return response.products.compactMap(result(from:))
    }

    private static func result(from product: OFFProduct) -> FoodResult? {
        guard let name = product.productName, !name.isEmpty else { return nil }
        return FoodResult(
            id: "off:\(product.code ?? UUID().uuidString)",
            name: name,
            brand: product.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
            proteinPer100g: product.nutriments?.proteins100g,
            proteinPerServing: product.nutriments?.proteinsServing,
            servingDescription: product.servingSize,
            source: .openFoodFacts
        )
    }

    // MARK: - USDA FoodData Central

    private static func searchUSDA(_ query: String) async throws -> [FoodResult] {
        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: usdaAPIKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "15"),
            URLQueryItem(name: "dataType", value: "Foundation,SR Legacy,Branded"),
        ]
        guard let url = components?.url else { throw URLError(.badURL) }

        let response: USDASearchResponse = try await fetch(url)
        return response.foods.map { food in
            // USDA search returns nutrient values per 100 g.
            let protein = food.foodNutrients.first {
                $0.nutrientNumber == "203" || $0.nutrientName == "Protein"
            }?.value
            return FoodResult(
                id: "usda:\(food.fdcId)",
                name: food.description.capitalized,
                brand: food.brandName ?? food.brandOwner,
                proteinPer100g: protein,
                proteinPerServing: nil,
                servingDescription: nil,
                source: .usda
            )
        }
    }

    // MARK: - Shared

    private static func fetch<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func dedupKey(_ result: FoodResult) -> String {
        "\(result.name.lowercased())|\(result.brand?.lowercased() ?? "")"
    }
}

// MARK: - Open Food Facts DTOs

private struct OFFSearchResponse: Decodable {
    let products: [OFFProduct]
}

private struct OFFProductResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let code: String?
    let productName: String?
    let brands: String?
    let servingSize: String?
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case nutriments
    }
}

/// OFF nutriment values arrive as numbers OR strings depending on the product — decode both.
private struct OFFNutriments: Decodable {
    let proteins100g: Double?
    let proteinsServing: Double?

    enum CodingKeys: String, CodingKey {
        case proteins100g = "proteins_100g"
        case proteinsServing = "proteins_serving"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        proteins100g = Self.flexibleDouble(container, .proteins100g)
        proteinsServing = Self.flexibleDouble(container, .proteinsServing)
    }

    private static func flexibleDouble(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Double? {
        if let double = try? container.decode(Double.self, forKey: key) { return double }
        if let string = try? container.decode(String.self, forKey: key) { return Double(string) }
        return nil
    }
}

// MARK: - USDA DTOs

private struct USDASearchResponse: Decodable {
    let foods: [USDAFood]
}

private struct USDAFood: Decodable {
    let fdcId: Int
    let description: String
    let brandName: String?
    let brandOwner: String?
    let foodNutrients: [USDANutrient]
}

private struct USDANutrient: Decodable {
    let nutrientNumber: String?
    let nutrientName: String?
    let value: Double?
}
