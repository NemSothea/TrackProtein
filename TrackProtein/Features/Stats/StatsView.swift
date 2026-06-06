import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    let profile: UserProfile

    @Query(sort: \ProteinEntry.date, order: .reverse) private var entries: [ProteinEntry]
    @State private var days = 7
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if PremiumStore.shared.isPremium {
                    statsContent
                } else {
                    lockedContent
                }
            }
            .navigationTitle("Stats")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Locked

    private var lockedContent: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Stats are Premium",
                systemImage: "chart.bar.fill",
                description: Text("Weekly trends, averages, and your top protein sources.")
            )
            Button {
                showPaywall = true
            } label: {
                Label("Unlock Premium", systemImage: "sparkles")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.proteinOrange)
        }
    }

    // MARK: - Stats

    private struct DayTotal: Identifiable {
        let date: Date
        let total: Double
        var id: Date { date }
    }

    private var dailyTotals: [DayTotal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.grams } }
        return (0..<days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayTotal(date: day, total: grouped[day] ?? 0)
        }
        .reversed()
    }

    private var average: Double {
        let totals = dailyTotals
        guard !totals.isEmpty else { return 0 }
        return totals.reduce(0) { $0 + $1.total } / Double(totals.count)
    }

    private var goalMetCount: Int {
        dailyTotals.filter { $0.total >= profile.dailyTargetGrams }.count
    }

    private var topSources: [(name: String, grams: Double)] {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: .now) else { return [] }
        return Dictionary(grouping: entries.filter { $0.date >= cutoff }, by: \.displayName)
            .map { (name: $0.key, grams: $0.value.reduce(0) { $0 + $1.grams }) }
            .sorted { $0.grams > $1.grams }
            .prefix(5)
            .map { $0 }
    }

    private var statsContent: some View {
        List {
            Section {
                Picker("Period", selection: $days) {
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section("Daily protein") {
                chart
                    .frame(height: 220)
                    .padding(.vertical, 8)
            }

            Section("Summary") {
                summaryRow("Average", "\(Int(average.rounded()))g / day")
                summaryRow("Goal hit", "\(goalMetCount) of \(days) days")
                if let best = dailyTotals.max(by: { $0.total < $1.total }), best.total > 0 {
                    summaryRow("Best day", "\(Int(best.total.rounded()))g · \(best.date.formatted(.dateTime.day().month()))")
                }
            }

            if !topSources.isEmpty {
                Section("Top protein sources") {
                    ForEach(topSources, id: \.name) { source in
                        HStack {
                            Text(source.name).lineLimit(1)
                            Spacer()
                            Text("\(Int(source.grams.rounded()))g")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.proteinOrange)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var chart: some View {
        Chart {
            ForEach(dailyTotals) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Protein", day.total)
                )
                .foregroundStyle(day.total >= profile.dailyTargetGrams ? Color.green : Color.proteinOrange)
                .cornerRadius(3)
            }
            RuleMark(y: .value("Goal", profile.dailyTargetGrams))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(.secondary)
                .annotation(position: .topTrailing) {
                    Text("Goal \(Int(profile.dailyTargetGrams))g")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: days == 7 ? 1 : 7)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.narrow))
            }
        }
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .bold()
                .foregroundStyle(Color.proteinOrange)
        }
    }
}
