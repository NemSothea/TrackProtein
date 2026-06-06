import SwiftUI

/// The hero ring — today's grams vs. goal at a glance.
struct ProgressRingView: View {
    let consumed: Double
    let target: Double

    private var progress: Double {
        guard target > 0 else { return 0 }
        return consumed / target
    }

    private var goalMet: Bool { progress >= 1 }

    private var ringColors: [Color] {
        goalMet ? [.green, .mint] : [.proteinOrange, .proteinDeep]
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 22)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    LinearGradient(colors: ringColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6), value: progress)

            VStack(spacing: 4) {
                Text("\(Int(consumed.rounded()))")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("of \(Int(target.rounded()))g")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                if goalMet {
                    Label("Goal hit!", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                } else {
                    Text("\(Int((target - consumed).rounded()))g to go")
                        .font(.subheadline)
                        .foregroundStyle(Color.proteinOrange)
                }
            }
        }
        .frame(width: 230, height: 230)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 40) {
        ProgressRingView(consumed: 85, target: 140)
        ProgressRingView(consumed: 150, target: 140)
    }
}
