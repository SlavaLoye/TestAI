import SwiftUI

extension Color {
    /// Initialize Color from a hex string like "#4A90E2" or "4A90E2"
    init(hex: String, alpha: Double = 1.0) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hexString.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self = Color(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: alpha
        )
    }
}

enum BrandColors {
    static let primaryBlue = Color(hex: "#4A90E2")
    static let accentRed = Color(hex: "#E53935")
    static let secondaryGreen = Color(hex: "#34C759")
    static let secondaryYellow = Color(hex: "#FFCC00")
}
