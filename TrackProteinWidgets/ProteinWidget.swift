import SwiftUI
import WidgetKit

struct ProteinWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ProteinWidget", provider: ProteinProvider()) { entry in
            ProteinWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "trackprotein://add"))
        }
        .configurationDisplayName("Protein Today")
        .description("Your daily protein progress at a glance. Tap to log.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct ProteinWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ProteinTimelineEntry

    var body: some View {
        switch family {
        case .systemMedium: MediumWidgetView(entry: entry)
        case .accessoryCircular: CircularWidgetView(entry: entry)
        case .accessoryRectangular: RectangularWidgetView(entry: entry)
        case .accessoryInline: InlineWidgetView(entry: entry)
        default: SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Shared ring

private struct WidgetRing: View {
    let entry: ProteinTimelineEntry

    private var colors: [Color] {
        entry.goalMet ? [.green, .mint] : [.proteinOrange, .proteinDeep]
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 10)
            Circle()
                .trim(from: 0, to: entry.progress)
                .stroke(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int(entry.consumed.rounded()))")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("of \(Int(entry.target.rounded()))g")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
        }
    }
}

private struct SetupPromptView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.pie.fill")
                .font(.title2)
                .foregroundStyle(Color.proteinOrange)
            Text("Open TrackProtein to set your goal")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Home screen families

private struct SmallWidgetView: View {
    let entry: ProteinTimelineEntry

    var body: some View {
        if entry.isConfigured {
            WidgetRing(entry: entry)
                .padding(2)
        } else {
            SetupPromptView()
        }
    }
}

private struct MediumWidgetView: View {
    let entry: ProteinTimelineEntry

    var body: some View {
        if entry.isConfigured {
            HStack(spacing: 16) {
                WidgetRing(entry: entry)
                    .frame(width: 110, height: 110)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Protein")
                        .font(.headline)
                    if entry.goalMet {
                        Label("Goal hit!", systemImage: "checkmark.circle.fill")
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                    } else {
                        Text("\(Int(entry.remaining.rounded()))g to go")
                            .font(.title3.bold())
                            .foregroundStyle(Color.proteinOrange)
                    }
                    if entry.streak > 0 {
                        Label("\(entry.streak) day streak", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Tap to log")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
        } else {
            SetupPromptView()
        }
    }
}

// MARK: - Lock screen families

private struct CircularWidgetView: View {
    let entry: ProteinTimelineEntry

    var body: some View {
        Gauge(value: entry.progress) {
            Text("g")
        } currentValueLabel: {
            Text("\(Int(entry.consumed.rounded()))")
                .font(.system(.body, design: .rounded).bold())
        }
        .gaugeStyle(.accessoryCircular)
    }
}

private struct RectangularWidgetView: View {
    let entry: ProteinTimelineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Protein", systemImage: "chart.pie.fill")
                .font(.headline)
            Text("\(Int(entry.consumed.rounded())) / \(Int(entry.target.rounded()))g")
                .font(.system(.body, design: .rounded).bold())
            ProgressView(value: entry.progress)
        }
    }
}

private struct InlineWidgetView: View {
    let entry: ProteinTimelineEntry

    var body: some View {
        if entry.isConfigured {
            Text("Protein \(Int(entry.consumed.rounded()))/\(Int(entry.target.rounded()))g")
        } else {
            Text("Set up TrackProtein")
        }
    }
}

#Preview("Small", as: .systemSmall) {
    ProteinWidget()
} timeline: {
    ProteinTimelineEntry(date: .now, consumed: 85, target: 140, streak: 4)
    ProteinTimelineEntry(date: .now, consumed: 150, target: 140, streak: 5)
}

#Preview("Medium", as: .systemMedium) {
    ProteinWidget()
} timeline: {
    ProteinTimelineEntry(date: .now, consumed: 85, target: 140, streak: 4)
}
