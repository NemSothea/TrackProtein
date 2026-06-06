import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack {
            switch viewModel.step {
            case 0: welcomeStep
            case 1: statsStep
            default: targetStep
            }
        }
        .padding()
        .animation(.easeInOut, value: viewModel.step)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.proteinOrange)
            Text("TrackProtein")
                .font(.largeTitle.bold())
            Text("Track protein. Nothing else.\nLog in under 3 seconds and hit your goal every day.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button { viewModel.step = 1 } label: {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.proteinOrange)
        }
    }

    // MARK: - Step 2: Weight + goal

    private var statsStep: some View {
        VStack(spacing: 32) {
            Text("About you")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                Text("\(Int(viewModel.weightKg)) kg")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.proteinOrange)
                Slider(value: $viewModel.weightKg, in: 30...200, step: 1)
                    .tint(.proteinOrange)
                Text("Your body weight")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(GoalType.allCases) { goal in
                    goalCard(goal)
                }
            }

            Spacer()

            Button { viewModel.step = 2 } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.proteinOrange)
        }
    }

    private func goalCard(_ goal: GoalType) -> some View {
        Button {
            viewModel.goalType = goal
            viewModel.customTarget = nil
        } label: {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title).font(.headline)
                    Text(goal.subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if viewModel.goalType == goal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.proteinOrange)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(viewModel.goalType == goal ? Color.proteinOrange : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Target

    private var targetStep: some View {
        VStack(spacing: 24) {
            Text("Your daily target")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            VStack(spacing: 12) {
                Text("\(Int(viewModel.finalTarget))g")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.proteinOrange)
                Text("protein per day")
                    .foregroundStyle(.secondary)

                HStack(spacing: 20) {
                    Button { viewModel.adjustTarget(by: -5) } label: {
                        Image(systemName: "minus.circle.fill").font(.title)
                    }
                    Button { viewModel.adjustTarget(by: 5) } label: {
                        Image(systemName: "plus.circle.fill").font(.title)
                    }
                }
                .tint(.proteinOrange)
            }

            Text("Based on \(Int(viewModel.weightKg)) kg × \(viewModel.goalType.gramsPerKg, specifier: "%.1f") g/kg for \(viewModel.goalType.title.lowercased()). You can change this anytime in Settings. This is general guidance, not medical advice.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: finishOnboarding) {
                Text("Start Tracking")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.proteinOrange)
        }
    }

    private func finishOnboarding() {
        context.insert(viewModel.makeProfile())
        for favorite in viewModel.makeStarterFavorites() {
            context.insert(favorite)
        }
        WidgetRefresher.refresh()
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserProfile.self, ProteinEntry.self, FavoriteFood.self], inMemory: true)
}
