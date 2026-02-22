import SwiftUI

/// Lightweight design tokens for widgets.
/// Mirrors DevineTheme from the main app but self-contained
/// so the widget extension doesn't depend on the main target.
enum WidgetTheme {
    enum Colors {
        static let bgPrimary = Color(light: 0xFFF8F5, dark: 0x17151C)
        static let surfaceCard = Color(light: 0xFFFFFF, dark: 0x1E1B26)
        static let textPrimary = Color(light: 0x1A1523, dark: 0xF5F0FA)
        static let textSecondary = Color(light: 0x6E6880, dark: 0x9B93AD)
        static let textMuted = Color(light: 0x9B93AD, dark: 0x6E6880)
        static let ctaPrimary = Color(light: 0xE54D8A, dark: 0xF472B6)
        static let successAccent = Color(light: 0x34D399, dark: 0x6EE7B7)
        static let warningAccent = Color(light: 0xFBBF24, dark: 0xFCD34D)
    }

    enum Gradients {
        static let heroCard: [Color] = [
            Color(light: 0xE54D8A, dark: 0xBE185D),
            Color(light: 0xC084FC, dark: 0x7C3AED),
        ]
        static let primaryCTA: [Color] = [
            Color(light: 0xE54D8A, dark: 0xF472B6),
            Color(light: 0xC084FC, dark: 0xA78BFA),
        ]
    }
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(
            UIColor { trait in
                let hex = trait.userInterfaceStyle == .dark ? dark : light
                let r = CGFloat((hex & 0xFF0000) >> 16) / 255
                let g = CGFloat((hex & 0x00FF00) >> 8) / 255
                let b = CGFloat((hex & 0x0000FF)) / 255
                return UIColor(red: r, green: g, blue: b, alpha: 1)
            }
        )
    }
}
