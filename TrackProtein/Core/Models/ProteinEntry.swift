import Foundation
import SwiftData

// All properties have defaults — required for CloudKit sync compatibility (enabled at launch).
@Model
final class ProteinEntry {
    var grams: Double = 0
    var label: String?
    /// The day/time the protein was consumed (user-editable for past-day logging).
    var date: Date = Date.now
    var sourceRaw: String = LogSource.manual.rawValue
    var createdAt: Date = Date.now

    var source: LogSource {
        get { LogSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    /// Label for display, defaulting when the entry was logged without one.
    var displayName: String {
        guard let label, !label.isEmpty else { return "Protein" }
        return label
    }

    init(grams: Double, label: String? = nil, date: Date = .now, source: LogSource = .manual, createdAt: Date = .now) {
        self.grams = grams
        self.label = label
        self.date = date
        self.sourceRaw = source.rawValue
        self.createdAt = createdAt
    }
}
