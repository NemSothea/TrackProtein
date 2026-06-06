import SwiftUI
import SwiftData
import PhotosUI

/// Premium gate — shows the paywall until the user is premium.
struct AIGateView: View {
    var body: some View {
        if PremiumStore.shared.isPremium {
            AILogView()
        } else {
            PaywallView()
        }
    }
}

/// Snap a meal or describe it — Claude estimates the protein, user confirms, entry logged.
struct AILogView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AILogViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $viewModel.mode) {
                        ForEach(AILogViewModel.Mode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                switch viewModel.mode {
                case .photo: photoSection
                case .describe: describeSection
                }

                estimateSection

                if let estimate = viewModel.estimate {
                    resultSection(estimate)
                }
            }
            .navigationTitle("AI Logging")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraPicker { image in
                    viewModel.selectedImage = image
                    viewModel.reset()
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Input sections

    private var photoSection: some View {
        Section("Meal photo") {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            HStack {
                PhotosPicker(selection: $viewModel.photoItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                }
                Spacer()
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        viewModel.showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera.fill")
                    }
                }
            }
            .tint(.proteinOrange)
        }
    }

    private var describeSection: some View {
        Section("What did you eat?") {
            TextField("e.g. 2 eggs and a protein shake", text: $viewModel.textInput, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private var estimateSection: some View {
        Section {
            Button {
                viewModel.runEstimate()
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.trailing, 6)
                        Text("Estimating…")
                    } else {
                        Label("Estimate Protein", systemImage: "sparkles")
                    }
                    Spacer()
                }
            }
            .disabled(!viewModel.canEstimate || viewModel.isLoading)
            .tint(.proteinOrange)
            .bold()

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Result

    private func resultSection(_ estimate: AIEstimate) -> some View {
        Section {
            ForEach(estimate.items) { item in
                HStack {
                    Text(item.name)
                    Spacer()
                    Text("~\(Int(item.grams.rounded()))g")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            VStack(spacing: 8) {
                Text("\(Int(viewModel.adjustedGrams))g")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.proteinOrange)
                    .contentTransition(.numericText())
                Text("Estimated range \(Int(estimate.lowGrams.rounded()))–\(Int(estimate.highGrams.rounded()))g · \(estimate.confidence) confidence")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $viewModel.adjustedGrams, in: 0...max(estimate.highGrams * 1.5, 50), step: 1)
                    .tint(.proteinOrange)
                Text("Adjust if the estimate looks off — it's an estimate, not a measurement.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)

            Button {
                viewModel.log(context: context)
                dismiss()
            } label: {
                HStack {
                    Spacer()
                    Label("Log \(Int(viewModel.adjustedGrams))g", systemImage: "checkmark.circle.fill")
                    Spacer()
                }
            }
            .bold()
            .tint(.proteinOrange)
            .disabled(viewModel.adjustedGrams <= 0)
        } header: {
            Text("Estimate")
        } footer: {
            if let notes = estimate.notes, !notes.isEmpty {
                Text(notes)
            }
        }
    }
}

/// Minimal camera wrapper for snapping a meal photo.
private struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
