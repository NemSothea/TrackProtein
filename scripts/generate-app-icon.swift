#!/usr/bin/env swift
// Generates the 1024×1024 app icon: white progress ring (75%, round caps)
// on the brand orange gradient. Re-run after design tweaks:
//   swift scripts/generate-app-icon.swift

import AppKit
import CoreGraphics

let size = 1024
guard
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
    let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
else {
    fatalError("Could not create graphics context")
}

// Background: proteinOrange → proteinDeep, top-left to bottom-right
let colors = [
    CGColor(red: 1.00, green: 0.50, blue: 0.26, alpha: 1),
    CGColor(red: 0.83, green: 0.22, blue: 0.08, alpha: 1),
] as CFArray
guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) else {
    fatalError("Could not create gradient")
}
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: CGFloat(size)),
    end: CGPoint(x: CGFloat(size), y: 0),
    options: []
)

let center = CGPoint(x: 512, y: 512)
let radius: CGFloat = 305
let lineWidth: CGFloat = 118

// Track: faint full circle
ctx.setLineWidth(lineWidth)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.25))
ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
ctx.strokePath()

// Progress: 75% arc from the top, clockwise, round caps (context is y-up)
ctx.setLineCap(.round)
ctx.setLineWidth(lineWidth)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.addArc(center: center, radius: radius, startAngle: .pi / 2, endAngle: -.pi, clockwise: true)
ctx.strokePath()

guard let image = ctx.makeImage() else { fatalError("Could not render image") }
let rep = NSBitmapImageRep(cgImage: image)
guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode PNG")
}

let output = "TrackProtein/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
do {
    try png.write(to: URL(fileURLWithPath: output))
    print("Wrote \(output)")
} catch {
    fatalError("Write failed: \(error)")
}
