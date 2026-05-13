import SwiftUI

enum DesignTokens {
    enum Color {
        static let brandGreen = SwiftUI.Color(red: 0x18 / 255.0, green: 0x80 / 255.0, blue: 0x46 / 255.0)
        static let brandGreenLight = SwiftUI.Color(red: 0x2e / 255.0, green: 0xb2 / 255.0, blue: 0x65 / 255.0)
        static let brandTint = SwiftUI.Color(red: 0xdf / 255.0, green: 0xf0 / 255.0, blue: 0xe2 / 255.0)
        static let pageBackground = SwiftUI.Color(red: 0xf2 / 255.0, green: 0xf7 / 255.0, blue: 0xf1 / 255.0)
        static let foreground = SwiftUI.Color(red: 0x17 / 255.0, green: 0x25 / 255.0, blue: 0x1d / 255.0)
        static let secondaryForeground = SwiftUI.Color(red: 0x5f / 255.0, green: 0x70 / 255.0, blue: 0x65 / 255.0)
    }

    enum Radius {
        static let card: CGFloat = 24
        static let chip: CGFloat = 16
    }
}
