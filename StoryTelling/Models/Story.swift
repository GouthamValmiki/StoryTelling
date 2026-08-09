import Foundation
import Combine

struct Story: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String
    let titleTe: String?
    let description: String
    let descriptionTe: String?
    let category: StoryCategory
    let ageRange: String
    let durationMinutes: Int
    let rating: Double
    let coverEmoji: String
    let coverGradient: [String] // hex colors, for Codable
    let isFeatured: Bool
    let isStoryOfDay: Bool
    let pages: [StoryPage]
    let discoverItems: [String]
    let discoverEmojis: [String]
    let languageSupport: [String]

    var readingTimeText: String { "\(durationMinutes) min" }
    var pageCount: Int { pages.count }

    func localizedTitle(lang: AppLanguage) -> String {
        if lang == .telugu, let te = titleTe, !te.isEmpty { return te }
        return title
    }
    func localizedDescription(lang: AppLanguage) -> String {
        if lang == .telugu, let te = descriptionTe, !te.isEmpty { return te }
        return description
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case telugu = "te"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .telugu: return "తెలుగు"
        }
    }
    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .telugu: return "🇮🇳"
        }
    }
}
