import SwiftUI
import UIKit

/// Frame the food into a square before estimation. The on-device model was trained on
/// plate-filling overhead shots, so its estimate collapses when the meal is small in a wide
/// photo (verified: the same bowl reads ~42 g framed tightly vs ~10 g with lots of table
/// around it). Letting the user zoom/pan to fill the frame is the fix — what's shown inside
/// the square here is exactly the pixels the model analyzes (WYSIWYG: the on-screen transform
/// and the exported crop use identical math).
struct PhotoCropView: View {
    let image: UIImage
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    /// Committed transform (persists between gestures).
    @State private var zoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    /// Live gesture deltas (auto-reset when the gesture ends).
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var drag: CGSize = .zero

    private let outputSide: CGFloat = 1024
    private let maxZoom: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let side = max(min(geo.size.width, geo.size.height) - 40, 120)
            let base = baseScale(viewport: side)
            let liveZoom = clampZoom(zoom * pinch)
            let dispW = image.size.width * base * liveZoom
            let dispH = image.size.height * base * liveZoom
            let liveOffset = clampOffset(
                CGSize(width: offset.width + drag.width, height: offset.height + drag.height),
                dispW: dispW, dispH: dispH, viewport: side
            )

            let magnify = MagnifyGesture()
                .updating($pinch) { value, state, _ in state = value.magnification }
                .onEnded { value in
                    zoom = clampZoom(zoom * value.magnification)
                    reclamp(viewport: side)
                }
            let pan = DragGesture()
                .updating($drag) { value, state, _ in state = value.translation }
                .onEnded { value in
                    offset = CGSize(width: offset.width + value.translation.width,
                                    height: offset.height + value.translation.height)
                    reclamp(viewport: side)
                }

            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("Frame the food")
                        .font(.headline)
                        .foregroundStyle(.white)
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: dispW, height: dispH)
                            .offset(liveOffset)
                    }
                    .frame(width: side, height: side)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.white.opacity(0.9), lineWidth: 2)
                    )
                    .contentShape(Rectangle())
                    .gesture(magnify.simultaneously(with: pan))

                    Text("Pinch to zoom · drag so the food fills the box")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Button(role: .cancel) { onCancel() } label: {
                            Text("Cancel").frame(maxWidth: .infinity)
                        }
                        .tint(.white)

                        Button { onConfirm(renderCrop(viewport: side)) } label: {
                            Text("Use Photo").bold().frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.proteinOrange)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.vertical, 24)
            }
        }
    }

    // MARK: - Transform math (shared by the on-screen preview and the exported crop)

    /// Fill the square viewport: the shorter image edge maps to the viewport side, so at
    /// zoom 1 there are never gaps. Matches `renderCrop`'s scaling exactly.
    private func baseScale(viewport: CGFloat) -> CGFloat {
        viewport / min(image.size.width, image.size.height)
    }

    private func clampZoom(_ z: CGFloat) -> CGFloat { min(max(z, 1), maxZoom) }

    /// Keep the (always ≥ viewport-sized) image covering the square — no empty edges.
    private func clampOffset(_ o: CGSize, dispW: CGFloat, dispH: CGFloat, viewport: CGFloat) -> CGSize {
        let maxX = max((dispW - viewport) / 2, 0)
        let maxY = max((dispH - viewport) / 2, 0)
        return CGSize(width: min(max(o.width, -maxX), maxX),
                      height: min(max(o.height, -maxY), maxY))
    }

    private func reclamp(viewport: CGFloat) {
        let base = baseScale(viewport: viewport)
        let z = clampZoom(zoom)
        offset = clampOffset(
            offset,
            dispW: image.size.width * base * z,
            dispH: image.size.height * base * z,
            viewport: viewport
        )
    }

    /// Render the framed square at `outputSide` px using the committed transform, scaled by
    /// `outputSide / viewport`. Because it mirrors the on-screen frame/offset one-to-one, the
    /// output is exactly what the user saw inside the box.
    private func renderCrop(viewport: CGFloat) -> UIImage {
        let base = baseScale(viewport: viewport)
        let z = clampZoom(zoom)
        let dispW = image.size.width * base * z
        let dispH = image.size.height * base * z
        let off = clampOffset(offset, dispW: dispW, dispH: dispH, viewport: viewport)
        let k = outputSide / viewport
        let rW = dispW * k, rH = dispH * k
        let originX = outputSide / 2 + off.width * k - rW / 2
        let originY = outputSide / 2 + off.height * k - rH / 2

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(
            size: CGSize(width: outputSide, height: outputSide), format: format
        ).image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: outputSide, height: outputSide))
            image.draw(in: CGRect(x: originX, y: originY, width: rW, height: rH))
        }
    }
}
