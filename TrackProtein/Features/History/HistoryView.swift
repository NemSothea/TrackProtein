import SwiftUI
import SwiftData

struct HistoryView: View {
    let profile: UserProfile

    @Query(sort: \ProteinEntry.date, order: .reverse) private var entries: [ProteinEntry]
    @State private var viewModel = HistoryViewModel()

    private var summaries: [DaySummary] {
        viewModel.summaries(from: entries)
    }

    private var streak: Int {
        StreakCalculator.currentStreak(entries: entries, goalGrams: profile.dailyTargetGrams)
    }

    var body: some View {
        NavigationStack {
            List {
                streakSection

                Section("Days") {
                    if summaries.isEmpty {
                        Text("No entries yet — start logging on the Today tab.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(summaries) { day in
                            dayRow(day)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("History")
            .sheet(item: $viewModel.selectedDay) { day in
                DayDetailView(day: day, profile: profile)
            }
        }
    }

    private var streakSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(streak > 0 ? Color.proteinOrange : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak) day\(streak == 1 ? "" : "s")")
                        .font(.title2.bold())
                    Text("Current streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func dayRow(_ day: DaySummary) -> some View {
        Button { viewModel.selectedDay = day } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.date, format: .dateTime.weekday(.wide))
                        .font(.headline)
                    Text(day.date, format: .dateTime.day().month().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(day.total.rounded()))g")
                    .font(.headline)
                    .foregroundStyle(day.total >= profile.dailyTargetGrams ? .green : Color.proteinOrange)
                Image(systemName: day.total >= profile.dailyTargetGrams ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(day.total >= profile.dailyTargetGrams ? .green : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Entries for a single day — supports deleting and logging to past days.
struct DayDetailView: View {
    let day: DaySummary
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Total")
                        Spacer()
                        Text("\(Int(day.total.rounded()))g of \(Int(profile.dailyTargetGrams.rounded()))g")
                            .bold()
                            .foregroundStyle(day.total >= profile.dailyTargetGrams ? .green : Color.proteinOrange)
                    }
                }
                Section("Entries") {
                    ForEach(day.entries) { entry in
                        HStack {
                            Text(entry.label?.isEmpty == false ? entry.label! : "Protein")
                            Spacer()
                            Text("\(Int(entry.grams.rounded()))g")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            context.delete(day.entries[index])
                        }
                        WidgetRefresher.refresh()
                        dismiss()
                    }
                }
            }
            .navigationTitle(day.date.formatted(.dateTime.day().month().year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAdd) {
                // Log to this past day at midday by default.
                QuickAddView(presetDate: day.date.addingTimeInterval(12 * 3600))
            }
        }
    }
}
