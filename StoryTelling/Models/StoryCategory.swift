import SwiftUI
import Combine

enum StoryCategory: String, CaseIterable, Codable, Identifiable {
    case adventure = "Adventure"
    case fantasy = "Fantasy"
    case space = "Space"
    case ocean = "Ocean"
    case animals = "Animals"
    case magic = "Magic"
    case friendship = "Friendship"
    case bedtime = "Bedtime"
    case learning = "Learning"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .adventure: return "🌳"
        case .fantasy: return "🦄"
        case .space: return "🚀"
        case .ocean: return "🐳"
        case .animals: return "🦁"
        case .magic: return "🧙"
        case .friendship: return "❤️"
        case .bedtime: return "🌈"
        case .learning: return "🧠"
        }
    }

    var gradient: [Color] {
        switch self {
        case .adventure: return [Color(hex: "2E7D32"), Color(hex: "81C784")]
        case .fantasy: return [Color(hex: "8E24AA"), Color(hex: "F48FB1")]
        case .space: return [Color(hex: "0D47A1"), Color(hex: "7C4DFF")]
        case .ocean: return [Color(hex: "006064"), Color(hex: "4DD0E1")]
        case .animals: return [Color(hex: "E65100"), Color(hex: "FFB74D")]
        case .magic: return [Color(hex: "4527A0"), Color(hex: "B39DDB")]
        case .friendship: return [Color(hex: "C2185B"), Color(hex: "F48FB1")]
        case .bedtime: return [Color(hex: "283593"), Color(hex: "CE93D8")]
        case .learning: return [Color(hex: "00695C"), Color(hex: "80CBC4")]
        }
    }

    var systemIcon: String {
        switch self {
        case .adventure: return "leaf.fill"
        case .fantasy: return "sparkles"
        case .space: return "star.fill"
        case .ocean: return "water.waves"
        case .animals: return "pawprint.fill"
        case .magic: return "wand.and.stars"
        case .friendship: return "heart.fill"
        case .bedtime: return "moon.fill"
        case .learning: return "lightbulb.fill"
        }
    }
}
