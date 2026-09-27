#!/usr/bin/env swift
//
//  make_android_icons.swift
//  Renders the LingoSwift launcher icons for Android.
//
//  Usage: swift Scripts/make_android_icons.swift android/app/src/main/res
//

import AppKit
import Foundation

let resRoot = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "android/app/src/main/res")

let canvas: CGFloat = 1024

let backgroundColors = [
    NSColor(srgbRed: 0.278, green: 0.514, blue: 0.996, alpha: 1.0),
    NSColor(srgbRed: 0.541, green: 0.263, blue: 0.984, alpha: 1.0),
]
let frontCardColor = NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.97)
let backCardColor = NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.28)
let frontLetterColor = NSColor(srgbRed: 0.322, green: 0.208, blue: 0.878, alpha: 1.0)
let backLetterColor = NSColor.white

/// Draws the A/文 cards inside `bounds` (a square in the 1024 canvas).
func drawCards(in bounds: NSRect) {
    let side = bounds.width
    let cardSide = side * 0.45
    let radius = cardSide * 0.22

    func card(originX: CGFloat, originY: CGFloat, fill: NSColor, letter: String, letterColor: NSColor) {
        let rect = NSRect(x: originX, y: originY, width: cardSide, height: cardSide)
        fill.setFill()
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()

        let font = NSFont.systemFont(ofSize: cardSide * 0.56, weight: .bold)
        let attributed = NSAttributedString(
            string: letter,
            attributes: [.font: font, .foregroundColor: letterColor]
        )
        let size = attributed.size()
        attributed.draw(at: NSPoint(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2 + cardSide * 0.02
        ))
    }

    // Back card (文), then front card (A).
    card(
        originX: bounds.minX + side * 0.34,
        originY: bounds.minY + side * 0.10,
        fill: backCardColor,
        letter: "文",
        letterColor: backLetterColor
    )
    card(
        originX: bounds.minX + side * 0.12,
        originY: bounds.minY + side * 0.30,
        fill: frontCardColor,
        letter: "A",
        letterColor: frontLetterColor
    )
}

func render(size: Int, circular: Bool, adaptiveForeground: Bool, to url: URL) throws {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: rep) else {
        throw NSError(domain: "make_android_icons", code: 1)
    }

    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.shouldAntialias = true

    let scale = CGFloat(size) / canvas
    let transform = NSAffineTransform()
    transform.scale(by: scale)
    transform.concat()

    if adaptiveForeground {
        // Standard adaptive icon: 108x108 canvas, keep artwork inside the safe zone.
        let side = canvas * 0.56
        drawCards(in: NSRect(
            x: (canvas - side) / 2,
            y: (canvas - side) / 2,
            width: side,
            height: side
        ))
    } else {
        let shape = circular
            ? NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: canvas, height: canvas))
            : NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: canvas, height: canvas), xRadius: 224, yRadius: 224)

        if let gradient = NSGradient(colors: backgroundColors) {
            gradient.draw(in: shape, angle: -90)
        } else {
            backgroundColors[0].setFill()
            shape.fill()
        }

        drawCards(in: NSRect(x: canvas * 0.14, y: canvas * 0.14, width: canvas * 0.72, height: canvas * 0.72))
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "make_android_icons", code: 2)
    }
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
    print("rendered \(url.path)")
}

struct Density {
    let folder: String
    let launcher: Int
    let adaptive: Int
}

let densities = [
    Density(folder: "mdpi", launcher: 48, adaptive: 108),
    Density(folder: "hdpi", launcher: 72, adaptive: 162),
    Density(folder: "xhdpi", launcher: 96, adaptive: 216),
    Density(folder: "xxhdpi", launcher: 144, adaptive: 324),
    Density(folder: "xxxhdpi", launcher: 192, adaptive: 432),
]

for density in densities {
    let mipmap = resRoot.appendingPathComponent("mipmap-\(density.folder)")
    try render(
        size: density.launcher,
        circular: false,
        adaptiveForeground: false,
        to: mipmap.appendingPathComponent("ic_launcher.png")
    )
    try render(
        size: density.launcher,
        circular: true,
        adaptiveForeground: false,
        to: mipmap.appendingPathComponent("ic_launcher_round.png")
    )
    try render(
        size: density.adaptive,
        circular: false,
        adaptiveForeground: true,
        to: resRoot.appendingPathComponent("drawable-\(density.folder)/ic_launcher_foreground.png")
    )
}
