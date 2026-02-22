#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let s: CGFloat = CGFloat(size)

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("Cannot create CGContext") }

// ─── Background ─────────────────────────────────────
let bgColors = [
    CGColor(red: 0x2D / 255, green: 0x0A / 255, blue: 0x3E / 255, alpha: 1),
    CGColor(red: 0xC8 / 255, green: 0x40 / 255, blue: 0x88 / 255, alpha: 1),
] as CFArray
guard let bgGrad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0, 1]) else {
    fatalError("Cannot create gradient")
}
ctx.drawLinearGradient(bgGrad, start: .zero, end: CGPoint(x: s, y: s), options: [])

// Warm center glow
let glowColors = [
    CGColor(red: 0xE5 / 255, green: 0x4D / 255, blue: 0x8A / 255, alpha: 0.22),
    CGColor(red: 0, green: 0, blue: 0, alpha: 0),
] as CFArray
if let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0, 1]) {
    ctx.drawRadialGradient(glow,
        startCenter: CGPoint(x: s * 0.50, y: s * 0.50), startRadius: 0,
        endCenter: CGPoint(x: s * 0.50, y: s * 0.50), endRadius: s * 0.46,
        options: [])
}

// ─── Butterfly using rotated ellipses ───────────────
// Each wing = an ellipse drawn at an angle from the body.
// This gives the organic, rounded wing shape butterflies have.

let bx = s * 0.50  // body center X
let by = s * 0.50  // body center Y

/// Draw a rotated filled ellipse
func drawRotatedEllipse(
    centerX: CGFloat, centerY: CGFloat,
    radiusX: CGFloat, radiusY: CGFloat,
    rotation: CGFloat,  // radians
    color: CGColor
) {
    ctx.saveGState()
    ctx.translateBy(x: centerX, y: centerY)
    ctx.rotate(by: rotation)
    ctx.setFillColor(color)
    ctx.fillEllipse(in: CGRect(x: -radiusX, y: -radiusY, width: radiusX * 2, height: radiusY * 2))
    ctx.restoreGState()
}

// ── Shadow layer ──
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.01), blur: s * 0.04,
              color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.30))

let white088 = CGColor(red: 1, green: 1, blue: 1, alpha: 0.88)
let white070 = CGColor(red: 1, green: 1, blue: 1, alpha: 0.70)

// Upper-left wing: large oval, tilted ~50° counter-clockwise
drawRotatedEllipse(
    centerX: bx - s * 0.16, centerY: by + s * 0.14,
    radiusX: s * 0.21, radiusY: s * 0.13,
    rotation: CGFloat.pi * 0.30,
    color: white088
)

// Upper-right wing: mirror
drawRotatedEllipse(
    centerX: bx + s * 0.16, centerY: by + s * 0.14,
    radiusX: s * 0.21, radiusY: s * 0.13,
    rotation: -CGFloat.pi * 0.30,
    color: white088
)

// Lower-left wing: smaller oval, tilted downward
drawRotatedEllipse(
    centerX: bx - s * 0.12, centerY: by - s * 0.12,
    radiusX: s * 0.15, radiusY: s * 0.09,
    rotation: -CGFloat.pi * 0.25,
    color: white070
)

// Lower-right wing: mirror
drawRotatedEllipse(
    centerX: bx + s * 0.12, centerY: by - s * 0.12,
    radiusX: s * 0.15, radiusY: s * 0.09,
    rotation: CGFloat.pi * 0.25,
    color: white070
)

ctx.restoreGState()  // end shadow

// ── Inner highlights: slightly brighter overlapping ovals ──
let white020 = CGColor(red: 1, green: 1, blue: 1, alpha: 0.18)

drawRotatedEllipse(
    centerX: bx - s * 0.14, centerY: by + s * 0.15,
    radiusX: s * 0.14, radiusY: s * 0.08,
    rotation: CGFloat.pi * 0.30,
    color: white020
)
drawRotatedEllipse(
    centerX: bx + s * 0.14, centerY: by + s * 0.15,
    radiusX: s * 0.14, radiusY: s * 0.08,
    rotation: -CGFloat.pi * 0.30,
    color: white020
)

// ─── Body: slim vertical oval ───────────────────────
let bodyW = s * 0.024
let bodyH = s * 0.18
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
ctx.fillEllipse(in: CGRect(x: bx - bodyW / 2, y: by - bodyH / 2, width: bodyW, height: bodyH))

// ─── Antennae ───────────────────────────────────────
func antenna(tipX: CGFloat, tipY: CGFloat, cpX: CGFloat, cpY: CGFloat) {
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.70))
    ctx.setLineWidth(s * 0.008)
    ctx.setLineCap(.round)

    let p = CGMutablePath()
    p.move(to: CGPoint(x: bx, y: by + bodyH * 0.45))
    p.addQuadCurve(to: CGPoint(x: tipX, y: tipY), control: CGPoint(x: cpX, y: cpY))
    ctx.addPath(p)
    ctx.strokePath()

    let r = s * 0.010
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.80))
    ctx.fillEllipse(in: CGRect(x: tipX - r, y: tipY - r, width: r * 2, height: r * 2))
    ctx.restoreGState()
}

// Antennae curve gently outward and up
antenna(tipX: s * 0.34, tipY: s * 0.78, cpX: s * 0.42, cpY: s * 0.72)
antenna(tipX: s * 0.66, tipY: s * 0.78, cpX: s * 0.58, cpY: s * 0.72)

// ─── Sparkles ───────────────────────────────────────
func sparkle(cx: CGFloat, cy: CGFloat, outerR: CGFloat, innerR: CGFloat, alpha: CGFloat) {
    ctx.saveGState()
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: alpha))
    let p = CGMutablePath()
    for i in 0..<8 {
        let angle = CGFloat(i) * .pi / 4
        let r = i % 2 == 0 ? outerR : innerR
        let pt = CGPoint(x: cx + r * cos(angle - .pi / 2), y: cy + r * sin(angle - .pi / 2))
        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
    }
    p.closeSubpath()
    ctx.addPath(p)
    ctx.fillPath()
    ctx.restoreGState()
}

sparkle(cx: s * 0.80, cy: s * 0.78, outerR: s * 0.024, innerR: s * 0.008, alpha: 0.65)
sparkle(cx: s * 0.18, cy: s * 0.74, outerR: s * 0.018, innerR: s * 0.006, alpha: 0.45)
sparkle(cx: s * 0.76, cy: s * 0.22, outerR: s * 0.016, innerR: s * 0.005, alpha: 0.45)
sparkle(cx: s * 0.22, cy: s * 0.26, outerR: s * 0.020, innerR: s * 0.007, alpha: 0.50)

// ─── Export ─────────────────────────────────────────
guard let image = ctx.makeImage() else { fatalError("Cannot create image") }
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
let url = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Cannot create image destination at \(outputPath)")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("Failed to write PNG") }
print("Icon generated: \(outputPath) (\(size)x\(size))")
