import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var stories: [Story] = []
    @Published var featured: Story?
    @Published var storyOfDay: Story?
    @Published var continueReading: [(Story, StoryProgress)] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    private let storyService: any StoryServiceProtocol
    private var storage: StorageService?

    init(storyService: any StoryServiceProtocol = MockStoryService()) {
        self.storyService = storyService
    }

    func inject(storage: StorageService) { self.storage = storage }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            stories = try await storyService.fetchStories()
            featured = try await storyService.fetchFeatured()
            storyOfDay = try await storyService.fetchStoryOfDay()
            if let s = storage {
                continueReading = s.continueReadingStories(allStories: stories)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var filteredStories: [Story] {
        if searchText.isEmpty { return stories }
        let q = searchText.lowercased()
        return stories.filter { $0.title.lowercased().contains(q) || $0.category.rawValue.lowercased().contains(q) }
    }

    var categories: [StoryCategory] { StoryCategory.allCases }

    func progress(for story: Story) -> Double {
        storage?.progress(for: story.id)?.progress ?? 0
    }
    func isFavorite(_ story: Story) -> Bool {
        storage?.progress(for: story.id)?.isFavorite ?? false
    }
}
