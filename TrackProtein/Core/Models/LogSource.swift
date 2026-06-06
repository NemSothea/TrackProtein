import Foundation

/// How a protein entry was logged. Search/barcode/AI arrive in Phases 2–3.
enum LogSource: String, Codable {
    case manual
    case favorite
    case search
    case barcode
    case ai
}
