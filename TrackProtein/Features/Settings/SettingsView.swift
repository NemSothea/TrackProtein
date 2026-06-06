import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var profile: UserProfile

    private var recommendedTarget: Double {
        GoalCalculator.dailyTarget(weightKg: profile.weightKg, goal: profile.goalType)
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

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onChange(of: profile.dailyTargetGrams) {
                // Target changes alter widget progress/goal state.
                WidgetRefresher.refresh()
            }
        }
    }
}
