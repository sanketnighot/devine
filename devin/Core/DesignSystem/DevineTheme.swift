import SwiftUI
import UIKit

enum DevineTheme {

    // MARK: - Colors

    enum Colors {
        // Backgrounds
        static let bgPrimary = Color(lightHex: 0xFFF8F5, darkHex: 0x17151C)
        static let bgSecondary = Color(lightHex: 0xF5F3F8, darkHex: 0x211E28)
        static let surfaceCard = Color(lightHex: 0xFFFFFF, darkHex: 0x2A2532)
        static let surfaceElevated = Color(lightHex: 0xFFFFFF, darkHex: 0x322C3B)

        // Text
        static let textPrimary = Color(lightHex: 0x1B1A1F, darkHex: 0xF5F0F6)
        static let textSecondary = Color(lightHex: 0x4F4D57, darkHex: 0xCEC7D6)
        static let textMuted = Color(lightHex: 0x7A7884, darkHex: 0xA69FB2)
        static let textOnGradient = Color.white

        // CTA
        static let ctaPrimary = Color(lightHex: 0xE76D9A, darkHex: 0xF08CB3)
        static let ctaPrimaryPressed = Color(lightHex: 0x5D3550, darkHex: 0xB87799)
        static let ctaSecondary = Color(lightHex: 0xF4A98A, darkHex: 0xE08F70)

        // Ring / Progress
        static let ringProgress = Color(lightHex: 0xE76D9A, darkHex: 0xF08CB3)
        static let ringTrack = Color(lightHex: 0xE9E6ED, darkHex: 0x3A3444)

        // Status
        static let successAccent = Color(lightHex: 0x2EAD73, darkHex: 0x46C488)
        static let warningAccent = Color(lightHex: 0xD98A2C, darkHex: 0xF0AA54)
        static let errorAccent = Color(lightHex: 0xC94A4A, darkHex: 0xDE6A6A)
        static let borderSubtle = Color(lightHex: 0xE9E6ED, darkHex: 0x413A4C)

        // Blush / accent fills
        static let blush = Color(lightHex: 0xF9D7E3, darkHex: 0x3D2836)
        static let peach = Color(lightHex: 0xFDE8DC, darkHex: 0x3B2A22)
        static let plum = Color(lightHex: 0x5D3550, darkHex: 0xD4A5C4)

        // Goal-specific accent tints
        static let goalFace = Color(lightHex: 0xE76D9A, darkHex: 0xF08CB3)
        static let goalSkin = Color(lightHex: 0xF4A98A, darkHex: 0xE08F70)
        static let goalBody = Color(lightHex: 0xE8826E, darkHex: 0xEF9A86)
        static let goalHair = Color(lightHex: 0xD4A05A, darkHex: 0xE8BD78)
        static let goalEnergy = Color(lightHex: 0xD9A82C, darkHex: 0xF0C454)
        static let goalConfidence = Color(lightHex: 0x9B6DB0, darkHex: 0xC49AD8)
    }

    // MARK: - Gradients

    enum Gradients {
        static let primaryCTA: [Color] = [
            Color(lightHex: 0xE76D9A, darkHex: 0xE76D9A),
            Color(lightHex: 0xF4A98A, darkHex: 0xF4A98A)
        ]

        static let heroCard: [Color] = [
            Color(lightHex: 0xE76D9A, darkHex: 0x5D3550),
            Color(lightHex: 0xF4A98A, darkHex: 0x7A4A3A)
        ]

        static let screenBackground: [Color] = [
            Color(lightHex: 0xFFF8F5, darkHex: 0x17151C),
            Color(lightHex: 0xF5F3F8, darkHex: 0x1D1A24)
        ]

        static let scoreRing: [Color] = [
            Color(lightHex: 0xE76D9A, darkHex: 0xF08CB3),
            Color(lightHex: 0xF4A98A, darkHex: 0xE08F70)
        ]

        static let celebration: [Color] = [
            Color(lightHex: 0xF9D7E3, darkHex: 0x5D3550),
            Color(lightHex: 0xFDE8DC, darkHex: 0x7A4A3A),
            Color(lightHex: 0xE8E4F0, darkHex: 0x3A3050)
        ]

        static let glass: [Color] = [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05)
        ]
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let pill: CGFloat = 100
    }

    // MARK: - Animation

    enum Motion {
        static let quick: Animation = .easeOut(duration: 0.2)
        static let standard: Animation = .easeInOut(duration: 0.3)
        static let expressive: Animation = .spring(response: 0.5, dampingFraction: 0.7)
        static let celebration: Animation = .spring(response: 0.6, dampingFraction: 0.6)
    }
}

// MARK: - GlowGoal Color Extension

extension GlowGoal {
    var accentColor: Color {
        switch self {
        case .faceDefinition: DevineTheme.Colors.goalFace
        case .skinGlow: DevineTheme.Colors.goalSkin
        case .bodySilhouette: DevineTheme.Colors.goalBody
        case .hairStyle: DevineTheme.Colors.goalHair
        case .energyFitness: DevineTheme.Colors.goalEnergy
        case .confidenceConsistency: DevineTheme.Colors.goalConfidence
        }
    }

    var iconName: String {
        switch self {
        case .faceDefinition: "face.smiling"
        case .skinGlow: "sparkles"
        case .bodySilhouette: "figure.stand"
        case .hairStyle: "comb"
        case .energyFitness: "bolt.fill"
        case .confidenceConsistency: "star.fill"
        }
    }
}

// MARK: - Color Helpers

private extension Color {
    init(lightHex: UInt32, darkHex: UInt32) {
        self.init(
            UIColor { trait in
                let hex = trait.userInterfaceStyle == .dark ? darkHex : lightHex
                return UIColor(hex: hex)
            }
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255
        let green = CGFloat((hex & 0x00FF00) >> 8) / 255
        let blue = CGFloat(hex & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
