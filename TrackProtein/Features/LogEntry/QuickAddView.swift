import SwiftUI
import SwiftData

/// Fast manual entry — the core interaction of the whole app.
struct QuickAddView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: QuickAddViewModel
    @FocusState private var gramsFocused: Bool

    private static let quickAmounts: [Double] = [5, 10, 20, 30]

    init(entry: ProteinEntry? = nil, presetDate: Date? = nil) {
        _viewModel = State(initialValue: QuickAddViewModel(entry: entry, presetDate: presetDate))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("0", text: $viewModel.gramsText)
                            .keyboardType(.decimalPad)
                            .focused($gramsFocused)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                        Text("g")
                            .font(.title2.bold())
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        ForEach(Self.quickAmounts, id: \.self) { amount in
                            Button("+\(Int(amount))") {
                                viewModel.addQuickAmount(amount)
                            }
                            .buttonStyle(.bordered)
                            .tint(.proteinOrange)
                        }
                    }
                } header: {
                    Text("Protein")
                }

                Section {
                    TextField("e.g. Chicken Breast", text: $viewModel.label)
                    DatePicker("When", selection: $viewModel.date, in: ...Date.now)
                    if !viewModel.isEditing {
                        Toggle("Save as favorite", isOn: $viewModel.saveAsFavorite)
                            .disabled(viewModel.label.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Details (optional)")
                } footer: {
                    if !viewModel.isEditing {
                        Text("Favorites appear on the home screen for one-tap logging.")
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Entry" : "Log Protein")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isEditing ? "Save" : "Log") {
                        viewModel.save(context: context)
                        dismiss()
                    }
                    .bold()
                    .disabled(!viewModel.isValid)
                }
            }
            .onAppear { gramsFocused = true }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    QuickAddView()
        .modelContainer(for: [UserProfile.self, ProteinEntry.self, FavoriteFood.self], inMemory: true)
}
