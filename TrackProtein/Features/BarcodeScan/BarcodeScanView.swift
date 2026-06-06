import SwiftUI
import VisionKit

struct BarcodeScanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BarcodeScanViewModel()

    private var scannerUsable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        NavigationStack {
            Group {
                if scannerUsable {
                    scannerContent
                } else {
                    ContentUnavailableView(
                        "Camera unavailable",
                        systemImage: "camera.fill",
                        description: Text("Barcode scanning needs a device camera and camera permission (Settings → TrackProtein).")
                    )
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $viewModel.foundFood, onDismiss: viewModel.rescan) { food in
                PortionPickerView(food: food, source: .barcode) {
                    dismiss()
                }
            }
        }
    }

    private var scannerContent: some View {
        ZStack {
            BarcodeScannerRepresentable(isScanning: $viewModel.isScanning) { code in
                viewModel.handleScan(code)
            }
            .ignoresSafeArea(edges: .bottom)

            VStack {
                Spacer()
                if viewModel.isLookingUp {
                    statusCard {
                        ProgressView("Looking up product…")
                    }
                } else if let code = viewModel.notFoundCode {
                    statusCard {
                        VStack(spacing: 10) {
                            Text("No protein data for this product")
                                .font(.headline)
                            Text("Barcode \(code) — try Food Search or log it manually.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Scan Again") { viewModel.rescan() }
                                .buttonStyle(.borderedProminent)
                                .tint(.proteinOrange)
                        }
                    }
                } else {
                    Text("Point the camera at a food barcode")
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 24)
                }
            }
        }
    }

    private func statusCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding()
    }
}

/// Thin VisionKit wrapper — emits barcode payloads via `onScan`.
private struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce, .code128])],
            qualityLevel: .fast,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        if isScanning {
            try? controller.startScanning()
        } else {
            controller.stopScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                if case .barcode(let barcode) = item, let payload = barcode.payloadStringValue {
                    onScan(payload)
                    return
                }
            }
        }
    }
}
