import SwiftUI
import UIKit

enum DevineTheme {
    enum Colors {
        static let bgPrimary = Color(lightHex: 0xFFF8F5, darkHex: 0x17151C)
        static let bgSecondary = Color(lightHex: 0xF5F3F8, darkHex: 0x211E28)
        static let surfaceCard = Color(lightHex: 0xFFFFFF, darkHex: 0x2A2532)

        static let textPrimary = Color(lightHex: 0x1B1A1F, darkHex: 0xF5F0F6)
        static let textSecondary = Color(lightHex: 0x4F4D57, darkHex: 0xCEC7D6)
        static let textMuted = Color(lightHex: 0x7A7884, darkHex: 0xA69FB2)

        static let ctaPrimary = Color(lightHex: 0xE76D9A, darkHex: 0xF08CB3)
        static let ctaPrimaryPressed = Color(lightHex: 0x5D3550, darkHex: 0xB87799)
        static let ctaSecondary = Color(lightHex: 0xF4A98A, darkHex: 0xE08F70)

        static let ringProgress = Color(lightHex: 0xE76D9A, darkHex: 0xF08CB3)
        static let ringTrack = Color(lightHex: 0xE9E6ED, darkHex: 0x3A3444)
        static let successAccent = Color(lightHex: 0x2EAD73, darkHex: 0x46C488)
        static let warningAccent = Color(lightHex: 0xD98A2C, darkHex: 0xF0AA54)
        static let errorAccent = Color(lightHex: 0xC94A4A, darkHex: 0xDE6A6A)
        static let borderSubtle = Color(lightHex: 0xE9E6ED, darkHex: 0x413A4C)
    }
}

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
