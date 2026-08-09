import Foundation
import Combine
import SwiftData

protocol StorageServiceProtocol {
    func progress(for storyId: String) -> StoryProgress?
    func updateProgress(storyId: String, pageIndex: Int, totalPages: Int)
    func toggleFavorite(storyId: String)
    func toggleOffline(storyId: String)
    func favorites() -> [String]
    func continueReadingStories(allStories: [Story]) -> [(Story, StoryProgress)]
    func markCompleted(storyId: String)
}

@MainActor
final class StorageService: StorageServiceProtocol {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func progress(for storyId: String) -> StoryProgress? {
        let d = FetchDescriptor<StoryProgress>(predicate: #Predicate { $0.storyId == storyId })
        return try? context.fetch(d).first
    }

    func updateProgress(storyId: String, pageIndex: Int, totalPages: Int) {
        let p = progress(for: storyId) ?? {
            let np = StoryProgress(storyId: storyId)
            context.insert(np)
            return np
        }()
        p.currentPageIndex = pageIndex
        p.progress = totalPages > 1 ? Double(pageIndex)/Double(totalPages-1) : 1
        p.lastReadDate = Date()
        try? context.save()
    }

    func toggleFavorite(storyId: String) {
        let p = progress(for: storyId) ?? {
            let np = StoryProgress(storyId: storyId)
            context.insert(np)
            return np
        }()
        p.isFavorite.toggle()
        try? context.save()
    }

    func toggleOffline(storyId: String) {
        let p = progress(for: storyId) ?? {
            let np = StoryProgress(storyId: storyId)
            context.insert(np)
            return np
        }()
        p.isOffline.toggle()
        try? context.save()
    }

    func favorites() -> [String] {
        let d = FetchDescriptor<StoryProgress>(predicate: #Predicate { $0.isFavorite == true })
        return (try? context.fetch(d).map { $0.storyId }) ?? []
    }

    func continueReadingStories(allStories: [Story]) -> [(Story, StoryProgress)] {
        let d = FetchDescriptor<StoryProgress>(predicate: #Predicate { $0.progress > 0 && $0.isCompleted == false })
        guard let list = try? context.fetch(d) else { return [] }
        return list.compactMap { prog in
            guard let s = allStories.first(where: { $0.id == prog.storyId }) else { return nil }
            return (s, prog)
        }.sorted { $0.1.lastReadDate > $1.1.lastReadDate }
    }

    func markCompleted(storyId: String) {
        let p = progress(for: storyId) ?? {
            let np = StoryProgress(storyId: storyId)
            context.insert(np)
            return np
        }()
        p.isCompleted = true
        p.progress = 1
        p.lastReadDate = Date()
        try? context.save()
    }

    // profile helpers via SwiftData fetch
    func fetchProfile() -> AppUserProfile? {
        let d = FetchDescriptor<AppUserProfile>()
        return try? context.fetch(d).first
    }
    func ensureProfile() -> AppUserProfile {
        if let p = fetchProfile() { return p }
        let n = AppUserProfile()
        context.insert(n)
        try? context.save()
        return n
    }
}
