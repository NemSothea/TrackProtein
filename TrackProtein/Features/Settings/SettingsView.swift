import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var profile: UserProfile

    @Query(sort: \ProteinEntry.date) private var entries: [ProteinEntry]
    @State private var showPaywall = false

    private var recommendedTarget: Double {
        GoalCalculator.dailyTarget(weightKg: profile.weightKg, goal: profile.goalType)
    }

    private var csvExport: String {
        var lines = ["date,label,grams,source"]
        let formatter = ISO8601DateFormatter()
        for entry in entries {
            let label = entry.displayName.replacingOccurrences(of: ",", with: " ")
            lines.append("\(formatter.string(from: entry.date)),\(label),\(entry.grams),\(entry.sourceRaw)")
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your stats") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("\(Int(profile.weightKg)) kg")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $profile.weightKg, in: 30...200, step: 1)
                        .tint(.proteinOrange)

                    Picker("Goal", selection: $profile.goalType) {
                        ForEach(GoalType.allCases) { goal in
                            Text(goal.title).tag(goal)
                        }
                    }
                }

                Section {
                    Stepper(value: $profile.dailyTargetGrams, in: 30...400, step: 5) {
                        HStack {
                            Text("Daily target")
                            Spacer()
                            Text("\(Int(profile.dailyTargetGrams))g")
                                .bold()
                                .foregroundStyle(Color.proteinOrange)
                        }
                    }
                    if profile.dailyTargetGrams != recommendedTarget {
                        Button("Use recommended (\(Int(recommendedTarget))g)") {
                            profile.dailyTargetGrams = recommendedTarget
                        }
                        .tint(.proteinOrange)
                    }
                } header: {
                    Text("Daily target")
                } footer: {
                    Text("Recommended: \(Int(recommendedTarget))g — \(profile.goalType.gramsPerKg, specifier: "%.1f") g/kg for \(profile.goalType.title.lowercased()). Not medical advice.")
                }

                Section("Data") {
                    if PremiumStore.shared.isPremium {
                        ShareLink(
                            item: csvExport,
                            preview: SharePreview("TrackProtein Export", icon: Image(systemName: "tablecells"))
                        ) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Export CSV", systemImage: "lock.fill")
                                .badge("Premium")
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onChange(of: profile.dailyTargetGrams) {
                // Target changes alter widget progress/goal state.
                WidgetRefresher.refresh()
            }
        }
    }
}
