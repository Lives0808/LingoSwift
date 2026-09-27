#!/usr/bin/env swift
//
//  make_icon.swift
//  Renders the LingoSwift app icon into an .iconset directory.
//
//  Usage: swift Scripts/make_icon.swift build/AppIcon.iconset
//

import AppKit
import Foundation

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
let outputURL = URL(fileURLWithPath: outputPath)

let canvas: CGFloat = 1024

let backgroundColors = [
    NSColor(srgbRed: 0.278, green: 0.514, blue: 0.996, alpha: 1.0),
    NSColor(srgbRed: 0.541, green: 0.263, blue: 0.984, alpha: 1.0),
]

let frontCardColor = NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.97)
let backCardColor = NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.28)
let frontLetterColor = NSColor(srgbRed: 0.322, green: 0.208, blue: 0.878, alpha: 1.0)
let backLetterColor = NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

func centeredAttributes(fontSize: CGFloat, color: NSColor) -> [NSAttributedString.Key: Any] {
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    return [
        .font: font,
        .foregroundColor: color,
    ]
}

func drawLetter(_ letter: String, in rect: NSRect, fontSize: CGFloat, color: NSColor) {
    let attributes = centeredAttributes(fontSize: fontSize, color: color)
    let attributed = NSAttributedString(string: letter, attributes: attributes)
    let textSize = attributed.size()
    let origin = NSPoint(
        x: rect.midX - textSize.width / 2,
        y: rect.midY - textSize.height / 2 + fontSize * 0.03
    )
    attributed.draw(at: origin)
}

func drawIcon(in size: CGFloat, to url: URL) throws {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "make_icon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap rep"])
    }

    rep.size = NSSize(width: size, height: size)

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        throw NSError(domain: "make_icon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create graphics context"])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let scale = size / canvas
    let transform = NSAffineTransform()
    transform.scale(by: scale)
    transform.concat()

    context.shouldAntialias = true

    // Background squircle.
    let backgroundRect = NSRect(x: 96, y: 96, width: 832, height: 832)
    let background = NSBezierPath(roundedRect: backgroundRect, xRadius: 196, yRadius: 196)
    if let gradient = NSGradient(colors: backgroundColors) {
        gradient.draw(in: background, angle: -90)
    } else {
        backgroundColors[0].setFill()
        background.fill()
    }

    // Back card with 文.
    let backCard = NSRect(x: 452, y: 268, width: 372, height: 372)
    backCardColor.setFill()
    NSBezierPath(roundedRect: backCard, xRadius: 82, yRadius: 82).fill()
    drawLetter("文", in: backCard, fontSize: 208, color: backLetterColor)

    // Front card with A.
    let frontCard = NSRect(x: 200, y: 404, width: 372, height: 372)
    frontCardColor.setFill()
    NSBezierPath(roundedRect: frontCard, xRadius: 82, yRadius: 82).fill()
    drawLetter("A", in: frontCard, fontSize: 210, color: frontLetterColor)

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "make_icon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG"])
    }
    try data.write(to: url)
}

let variants: [(name: String, size: CGFloat)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

for variant in variants {
    let fileURL = outputURL.appendingPathComponent("\(variant.name).png")
    try drawIcon(in: variant.size, to: fileURL)
    print("rendered \(fileURL.path)")
}
