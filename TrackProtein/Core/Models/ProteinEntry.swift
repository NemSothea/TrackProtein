import Foundation
import SwiftData

@Model
final class ProteinEntry {
    var grams: Double
    var label: String?
    /// The day/time the protein was consumed (user-editable for past-day logging).
    var date: Date
    var sourceRaw: String
    var createdAt: Date

    var source: LogSource {
        get { LogSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    init(grams: Double, label: String? = nil, date: Date = .now, source: LogSource = .manual, createdAt: Date = .now) {
        self.grams = grams
        self.label = label
        self.date = date
        self.sourceRaw = source.rawValue
        self.createdAt = createdAt
    }
}
