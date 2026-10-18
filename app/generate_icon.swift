import Cocoa

func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // High quality antialiasing
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    // Squircle path (macOS icon squircle)
    let inset = s * 0.08
    let iconRect = CGRect(x: inset, y: inset, width: s - (inset * 2), height: s - (inset * 2))
    let cornerRadius = iconRect.width * 0.225
    let clipPath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    ctx.saveGState()
    ctx.addPath(clipPath)
    ctx.clip()

    // 1. Dark Liquid Obsidian Background Gradient
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.12, green: 0.08, blue: 0.22, alpha: 1.0).cgColor,
        NSColor(red: 0.05, green: 0.04, blue: 0.09, alpha: 1.0).cgColor,
        NSColor(red: 0.02, green: 0.02, blue: 0.04, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.5, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGradient, start: CGPoint(x: s/2, y: s), end: CGPoint(x: s/2, y: 0), options: [])
    }

    // 2. Radial Glowing Nebula
    let glowColors = [
        NSColor(red: 0.65, green: 0.25, blue: 0.98, alpha: 0.55).cgColor,
        NSColor(red: 0.25, green: 0.55, blue: 0.98, alpha: 0.25).cgColor,
        NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor
    ] as CFArray
    let glowLocations: [CGFloat] = [0.0, 0.45, 1.0]
    if let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: glowLocations) {
        ctx.drawRadialGradient(glowGradient, startCenter: CGPoint(x: s * 0.5, y: s * 0.65), startRadius: 0, endCenter: CGPoint(x: s * 0.5, y: s * 0.65), endRadius: s * 0.5, options: [])
    }

    // 3. Floating Apple Camera Notch (Center Top)
    let notchWidth = s * 0.52
    let notchHeight = s * 0.18
    let notchX = (s - notchWidth) / 2
    let notchY = s * 0.58
    let notchRect = CGRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
    let notchCorner = notchHeight * 0.42

    let notchPath = CGPath(roundedRect: notchRect, cornerWidth: notchCorner, cornerHeight: notchCorner, transform: nil)

    // Notch Drop Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.02), blur: s * 0.04, color: NSColor.black.withAlphaComponent(0.8).cgColor)
    ctx.setFillColor(NSColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0).cgColor)
    ctx.addPath(notchPath)
    ctx.fillPath()
    ctx.restoreGState()

    // Notch Specular Border
    ctx.saveGState()
    ctx.addPath(notchPath)
    ctx.setLineWidth(max(1.0, s * 0.012))
    ctx.setStrokeColor(NSColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 0.7).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    // 4. Camera Aperture Lens inside notch
    let lensRadius = notchHeight * 0.22
    let lensCenter = CGPoint(x: s * 0.5, y: notchY + (notchHeight / 2))
    ctx.saveGState()
    ctx.setFillColor(NSColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1.0).cgColor)
    ctx.fillEllipse(in: CGRect(x: lensCenter.x - lensRadius, y: lensCenter.y - lensRadius, width: lensRadius * 2, height: lensRadius * 2))
    ctx.setStrokeColor(NSColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 0.6).cgColor)
    ctx.setLineWidth(max(1.0, s * 0.006))
    ctx.strokeEllipse(in: CGRect(x: lensCenter.x - lensRadius, y: lensCenter.y - lensRadius, width: lensRadius * 2, height: lensRadius * 2))

    // Camera Green Indicator LED dot
    let ledRadius = lensRadius * 0.38
    let ledCenter = CGPoint(x: lensCenter.x + (notchWidth * 0.25), y: lensCenter.y)
    ctx.setFillColor(NSColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 0.95).cgColor)
    ctx.fillEllipse(in: CGRect(x: ledCenter.x - ledRadius, y: ledCenter.y - ledRadius, width: ledRadius * 2, height: ledRadius * 2))
    ctx.restoreGState()

    // 5. Ambient Glowing Soundwave & Aura beneath notch
    let waveWidth = s * 0.58
    let waveStartX = (s - waveWidth) / 2
    let waveY = s * 0.36
    let barCount = 11
    let barSpacing = waveWidth / CGFloat(barCount)
    let heights: [CGFloat] = [0.08, 0.14, 0.22, 0.16, 0.26, 0.32, 0.24, 0.18, 0.22, 0.12, 0.07]

    for i in 0..<barCount {
        let barX = waveStartX + (CGFloat(i) * barSpacing)
        let barH = heights[i] * s
        let barW = max(2.0, s * 0.024)
        let barRect = CGRect(x: barX, y: waveY - (barH / 2), width: barW, height: barH)
        let barPath = CGPath(roundedRect: barRect, cornerWidth: barW / 2, cornerHeight: barW / 2, transform: nil)

        ctx.saveGState()
        let t = CGFloat(i) / CGFloat(barCount - 1)
        let r = 0.65 + (0.25 * t)
        let g = 0.35 + (0.2 * (1.0 - t))
        let b = 0.95
        ctx.setFillColor(NSColor(red: r, green: g, blue: b, alpha: 0.9).cgColor)
        ctx.setShadow(offset: .zero, blur: s * 0.02, color: NSColor(red: r, green: g, blue: b, alpha: 0.6).cgColor)
        ctx.addPath(barPath)
        ctx.fillPath()
        ctx.restoreGState()
    }

    ctx.restoreGState() // restore clip

    // 6. Outer Specular Squircle Rim / Gloss
    ctx.saveGState()
    ctx.addPath(clipPath)
    ctx.setLineWidth(max(1.5, s * 0.015))
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.22).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    image.unlockFocus()
    return image
}

let fileManager = FileManager.default
let iconsetDir = URL(fileURLWithPath: "AuraNotch.iconset")
try? fileManager.removeItem(at: iconsetDir)
try? fileManager.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let sizes: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for item in sizes {
    let img = generateIcon(size: item.size)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let dest = iconsetDir.appendingPathComponent(item.name)
        try? png.write(to: dest)
    }
}

print("✅ Successfully generated AuraNotch.iconset with \(sizes.count) image assets.")
