import Foundation
import Combine
import SwiftData

@Model
final class StoryProgress {
    var storyId: String
    var currentPageIndex: Int
    var isCompleted: Bool
    var isFavorite: Bool
    var isOffline: Bool
    var lastReadDate: Date
    var progress: Double // 0..1
    var readingMinutes: Int

    init(storyId: String, currentPageIndex: Int = 0, isCompleted: Bool = false, isFavorite: Bool = false, isOffline: Bool = false, lastReadDate: Date = Date(), progress: Double = 0, readingMinutes: Int = 0) {
        self.storyId = storyId
        self.currentPageIndex = currentPageIndex
        self.isCompleted = isCompleted
        self.isFavorite = isFavorite
        self.isOffline = isOffline
        self.lastReadDate = lastReadDate
        self.progress = progress
        self.readingMinutes = readingMinutes
    }
}

@Model
final class AppUserProfile {
    var name: String
    var avatarEmoji: String
    var favoriteGenreRaw: String
    var streakDays: Int
    var totalStoriesCompleted: Int
    var totalMinutes: Int
    var lastStreakDate: Date?
    var badges: [String] // badge ids
    var preferredLanguageRaw: String
    var agePreference: String

    init(name: String = "Alex", avatarEmoji: String = "👦", favoriteGenreRaw: String = StoryCategory.adventure.rawValue, streakDays: Int = 3, totalStoriesCompleted: Int = 7, totalMinutes: Int = 222, badges: [String] = ["first_adventure", "book_explorer"], preferredLanguageRaw: String = AppLanguage.english.rawValue, agePreference: String = "5-8") {
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.favoriteGenreRaw = favoriteGenreRaw
        self.streakDays = streakDays
        self.totalStoriesCompleted = totalStoriesCompleted
        self.totalMinutes = totalMinutes
        self.lastStreakDate = Date()
        self.badges = badges
        self.preferredLanguageRaw = preferredLanguageRaw
        self.agePreference = agePreference
    }

    var favoriteGenre: StoryCategory {
        StoryCategory(rawValue: favoriteGenreRaw) ?? .adventure
    }
    var language: AppLanguage {
        AppLanguage(rawValue: preferredLanguageRaw) ?? .english
    }
}
