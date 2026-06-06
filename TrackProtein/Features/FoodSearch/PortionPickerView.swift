import SwiftUI
import SwiftData

/// Picks how much of a found food was eaten and logs the resulting protein.
struct PortionPickerView: View {
    let food: FoodResult
    let source: LogSource
    /// Called after logging so the presenting flow can dismiss itself too.
    var onLogged: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var foodGrams: Double = 100
    @State private var servings: Double = 1
    @State private var saveAsFavorite = false

    private static let quickPortions: [Double] = [50, 100, 150, 200]

    /// Per-100g data drives a grams slider; serving-only data drives a servings stepper.
    private var usesPer100g: Bool { food.proteinPer100g != nil }

    private var protein: Double {
        if let per100 = food.proteinPer100g {
            return per100 * foodGrams / 100
        }
        return (food.proteinPerServing ?? 0) * servings
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.name).font(.headline)
                        Text([food.brand, food.source.rawValue].compactMap(\.self).joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Portion") {
                    if usesPer100g {
                        per100gPicker
                    } else {
                        servingsPicker
                    }
                }

                Section {
                    HStack {
                        Text("Protein")
                        Spacer()
                        Text("\(Int(protein.rounded()))g")
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundStyle(Color.proteinOrange)
                            .contentTransition(.numericText())
                    }
                    Toggle("Save as favorite", isOn: $saveAsFavorite)
                }
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") { log() }
                        .bold()
                        .disabled(protein <= 0)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var per100gPicker: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(Int(foodGrams))g of food")
                    .font(.system(.title3, design: .rounded).bold())
                Spacer()
            }
            Slider(value: $foodGrams, in: 10...500, step: 5)
                .tint(.proteinOrange)
            HStack(spacing: 8) {
                ForEach(Self.quickPortions, id: \.self) { portion in
                    Button("\(Int(portion))g") {
                        withAnimation { foodGrams = portion }
                    }
                    .buttonStyle(.bordered)
                    .tint(.proteinOrange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var servingsPicker: some View {
        Stepper(value: $servings, in: 0.5...10, step: 0.5) {
            HStack {
                Text(servings == 1 ? "1 serving" : String(format: "%g servings", servings))
                if let description = food.servingDescription {
                    Text("(\(description))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func log() {
        context.insert(ProteinEntry(grams: protein, label: food.name, source: source))
        if saveAsFavorite {
            let favorite = FavoriteFood(name: food.name, grams: protein)
            favorite.lastUsedHour = Calendar.current.component(.hour, from: .now)
            context.insert(favorite)
        }
        WidgetRefresher.refresh()
        dismiss()
        onLogged()
    }
}
