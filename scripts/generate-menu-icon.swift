#!/usr/bin/env swift

import AppKit

func createMenuBarIcon(size: CGFloat, scale: CGFloat) -> NSImage? {
    let pointSize = CGSize(width: size, height: size)
    let pixelSize = CGSize(width: size * scale, height: size * scale)

    // Create bitmap rep directly
    guard let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(pixelSize.width),
        pixelsHigh: Int(pixelSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }

    bitmapRep.size = pointSize

    // Draw into bitmap context
    guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    // Configure SF Symbol sizes
    let bubbleSize = size * 0.90
    let sparkleRatio: CGFloat = 1.0 / 2.0
    let sparkleSize = bubbleSize * sparkleRatio
    let sparkleOffsetY = bubbleSize * (1.0 / 10.0)

    // Get SF Symbols with template rendering mode
    let bubbleConfig = NSImage.SymbolConfiguration(pointSize: bubbleSize, weight: .semibold)
    let sparkleConfig = NSImage.SymbolConfiguration(pointSize: sparkleSize, weight: .light)

    guard let bubbleSymbol = NSImage(systemSymbolName: "bubble.left", accessibilityDescription: nil)?
            .withSymbolConfiguration(bubbleConfig),
          let sparkleSymbol = NSImage(systemSymbolName: "sparkle", accessibilityDescription: nil)?
            .withSymbolConfiguration(sparkleConfig) else {
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }

    // Draw bubble centered (full canvas, symbol centers itself)
    let bubbleCanvas = NSRect(x: 0, y: 0, width: size, height: size)
    bubbleSymbol.draw(in: bubbleCanvas)

    // Draw sparkle in a smaller rect, centered horizontally, offset vertically
    let sparkleRect = NSRect(
        x: (size - sparkleSize) / 2,
        y: (size - sparkleSize) / 2 + sparkleOffsetY,
        width: sparkleSize,
        height: sparkleSize
    )
    sparkleSymbol.draw(in: sparkleRect)

    NSGraphicsContext.restoreGraphicsState()

    // Create final image
    let finalImage = NSImage(size: pointSize)
    finalImage.addRepresentation(bitmapRep)
    return finalImage
}

func savePNG(image: NSImage, to path: String) -> Bool {
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        return false
    }

    let url = URL(fileURLWithPath: path)

    // Create directory if needed
    let directory = url.deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    do {
        try pngData.write(to: url)
        return true
    } catch {
        print("Error writing file: \(error)")
        return false
    }
}

// Get script directory to calculate project root
let scriptPath = CommandLine.arguments[0]
let scriptURL = URL(fileURLWithPath: scriptPath)
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent().path

// Define output paths
let assetPath = "\(projectRoot)/Your Turn/Your Turn/Assets.xcassets/MenuBarIcon.imageset"
let icon1xPath = "\(assetPath)/MenuBarIcon@1x.png"
let icon2xPath = "\(assetPath)/MenuBarIcon@2x.png"

print("Generating menu bar icons...")

// Generate @1x (18x18 pixels at 1x scale)
if let image1x = createMenuBarIcon(size: 18, scale: 1.0) {
    if savePNG(image: image1x, to: icon1xPath) {
        print("✓ Generated @1x (18x18): \(icon1xPath)")
    } else {
        print("✗ Failed to save @1x")
    }
} else {
    print("✗ Failed to render @1x")
}

// Generate @2x (36x36 pixels at 2x scale for 18pt icon)
if let image2x = createMenuBarIcon(size: 18, scale: 2.0) {
    if savePNG(image: image2x, to: icon2xPath) {
        print("✓ Generated @2x (36x36): \(icon2xPath)")
    } else {
        print("✗ Failed to save @2x")
    }
} else {
    print("✗ Failed to render @2x")
}

print("Done!")
