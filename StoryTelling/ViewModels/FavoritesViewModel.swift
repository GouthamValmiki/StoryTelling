import Foundation
import Combine

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var stories: [Story] = []
    @Published var allStories: [Story] = []

    private let service: any StoryServiceProtocol
    private var storage: StorageService?
    init(service: any StoryServiceProtocol = MockStoryService()) { self.service = service }
    func inject(_ s: StorageService) { storage = s }

    func load() async {
        allStories = (try? await service.fetchStories()) ?? []
        refresh()
    }
    func refresh() {
        guard let storage else { return }
        let favIds = Set(storage.favorites())
        stories = allStories.filter { favIds.contains($0.id) }
    }
    func remove(_ story: Story) {
        storage?.toggleFavorite(storyId: story.id)
        refresh()
    }
}
