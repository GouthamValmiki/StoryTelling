import SwiftUI
import Combine

enum AppColors {
    static let primaryDeep = Color(hex: "1A1033") // deep purple midnight
    static let primary = Color(hex: "3A1F6B")
    static let secondary = Color(hex: "C9B6FF") // lavender
    static let accent = Color(hex: "FFD54F") // warm yellow
    static let accent2 = Color(hex: "FF8E53")
    static let sky = Color(hex: "7EC8E3")
    static let pink = Color(hex: "F8BBD0")
    static let mint = Color(hex: "A7FFEB")
    static let background = Color(hex: "0F0A1E")
    static let card = Color(hex: "221845")
    static let cardLight = Color(hex: "2E1F5E")

    static let gradientPrimary = LinearGradient(colors: [Color(hex: "3A1F6B"), Color(hex: "7C4DFF")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let gradientAccent = LinearGradient(colors: [Color(hex: "FFD54F"), Color(hex: "FF8E53")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let gradientNight = LinearGradient(colors: [Color(hex: "0F0A1E"), Color(hex: "1A1033"), Color(hex: "2E1F5E")], startPoint: .top, endPoint: .bottom)
    static let gradientOcean = LinearGradient(colors: [Color(hex: "004D40"), Color(hex: "00796B")], startPoint: .top, endPoint: .bottom)
}

// MARK: - Color hex helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
    func toHex() -> String {
        // placeholder
        return "000000"
    }
}
