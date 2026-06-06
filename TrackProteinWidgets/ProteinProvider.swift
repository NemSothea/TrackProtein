import WidgetKit
import SwiftData

struct ProteinTimelineEntry: TimelineEntry {
    let date: Date
    let consumed: Double
    let target: Double
    let streak: Int

    var isConfigured: Bool { target > 0 }
    var goalMet: Bool { isConfigured && consumed >= target }
    var progress: Double { isConfigured ? min(consumed / target, 1) : 0 }
    var remaining: Double { max(target - consumed, 0) }
}

struct ProteinProvider: TimelineProvider {
    private static let container = SharedStore.makeContainer()

    func placeholder(in context: Context) -> ProteinTimelineEntry {
        ProteinTimelineEntry(date: .now, consumed: 85, target: 140, streak: 4)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProteinTimelineEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProteinTimelineEntry>) -> Void) {
        // The app reloads timelines on every mutation; this policy just resets the ring at midnight.
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        completion(Timeline(entries: [loadEntry()], policy: .after(nextMidnight)))
    }

    private func loadEntry() -> ProteinTimelineEntry {
        let context = ModelContext(Self.container)
        let profile = ((try? context.fetch(FetchDescriptor<UserProfile>())) ?? []).first
        let entries = (try? context.fetch(FetchDescriptor<ProteinEntry>())) ?? []

        let target = profile?.dailyTargetGrams ?? 0
        let consumed = entries.filter { $0.date.isToday }.reduce(0) { $0 + $1.grams }
        let streak = StreakCalculator.currentStreak(entries: entries, goalGrams: target)

        return ProteinTimelineEntry(date: .now, consumed: consumed, target: target, streak: streak)
    }
}
