import Foundation
import Combine

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var stories: [Story] = []
    @Published var selectedCategory: StoryCategory? = nil
    @Published var searchText = ""
    @Published var isLoading = false

    private let service: any StoryServiceProtocol
    init(service: any StoryServiceProtocol = MockStoryService()) { self.service = service }

    func load() async {
        isLoading = true
        stories = (try? await service.fetchStories()) ?? []
        isLoading = false
    }

    var filtered: [Story] {
        var list = stories
        if let cat = selectedCategory { list = list.filter { $0.category == cat } }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter { $0.title.lowercased().contains(q) || $0.description.lowercased().contains(q) }
        }
        return list
    }

    var suggested = ["Magical","Space","Ocean","Animals"]
}
