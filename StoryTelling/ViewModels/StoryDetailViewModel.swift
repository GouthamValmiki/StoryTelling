import Foundation
import Combine

@MainActor
final class StoryDetailViewModel: ObservableObject {
    @Published var story: Story
    @Published var isFavorite: Bool = false
    @Published var isOffline: Bool = false
    @Published var showPDFShare = false
    @Published var pdfURL: URL?

    private var storage: StorageService?

    init(story: Story, storage: StorageService? = nil) {
        self.story = story
        self.storage = storage
        if let s = storage {
            isFavorite = s.progress(for: story.id)?.isFavorite ?? false
            isOffline = s.progress(for: story.id)?.isOffline ?? false
        }
    }
    func inject(_ s: StorageService) {
        storage = s
        isFavorite = s.progress(for: story.id)?.isFavorite ?? false
        isOffline = s.progress(for: story.id)?.isOffline ?? false
    }
    func toggleFavorite() {
        storage?.toggleFavorite(storyId: story.id)
        isFavorite.toggle()
    }
    func toggleOffline() {
        storage?.toggleOffline(storyId: story.id)
        isOffline.toggle()
    }
    func generatePDF(lang: AppLanguage) {
        pdfURL = PDFService.generatePDF(for: story, language: lang)
        showPDFShare = pdfURL != nil
    }
}
