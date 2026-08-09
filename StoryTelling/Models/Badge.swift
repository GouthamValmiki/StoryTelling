import SwiftUI
import Combine

struct Badge: Identifiable, Hashable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let color: Color

    static let all: [Badge] = [
        Badge(id: "first_adventure", emoji: "🌟", title: "First Adventure", description: "Completed your first story", color: Color(hex: "FFD54F")),
        Badge(id: "book_explorer", emoji: "📚", title: "Book Explorer", description: "Read 5 stories", color: Color(hex: "90CAF9")),
        Badge(id: "seven_day", emoji: "🔥", title: "7-Day Reader", description: "7 day streak", color: Color(hex: "FF8A65")),
        Badge(id: "bedtime_hero", emoji: "🌙", title: "Bedtime Hero", description: "Read 3 bedtime stories", color: Color(hex: "B39DDB")),
        Badge(id: "space_explorer", emoji: "🚀", title: "Space Explorer", description: "Completed a space story", color: Color(hex: "81D4FA")),
        Badge(id: "ocean_keeper", emoji: "🐳", title: "Ocean Keeper", description: "Completed ocean tale", color: Color(hex: "80CBC4")),
        Badge(id: "magic_seeker", emoji: "🧙", title: "Magic Seeker", description: "Finished a magic story", color: Color(hex: "CE93D8"))
    ]
}
