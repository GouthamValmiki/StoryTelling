import Foundation
import Combine

@MainActor
final class ReaderViewModel: ObservableObject {
    @Published var story: Story
    @Published var currentIndex: Int = 0
    @Published var isAutoPlay = false
    @Published var showEnding = false
    @Published var chosenPath: [String] = []

    private var storage: StorageService?
    private var autoTask: Task<Void, Never>?

    // linear pages vs branching: we navigate via nextPageId mapping
    private var pageIdToLinearIndex: [String:Int] = [:]

    init(story: Story, startIndex: Int = 0, storage: StorageService? = nil) {
        self.story = story
        self.storage = storage
        if let p = storage?.progress(for: story.id) {
            self.currentIndex = min(p.currentPageIndex, story.pages.count-1)
        } else {
            self.currentIndex = startIndex
        }
        buildMap()
    }

    func inject(_ s: StorageService) { storage = s }

    private func buildMap() {
        for (i,p) in story.pages.enumerated() { pageIdToLinearIndex[p.id]=i }
    }

    var currentPage: StoryPage { story.pages[currentIndex] }
    var progress: Double { Double(currentIndex+1)/Double(story.pages.count) }
    var canGoNext: Bool { currentIndex < story.pages.count-1 }
    var canGoPrev: Bool { currentIndex > 0 }

    func next() {
        if currentIndex < story.pages.count-1 {
            // if current has choice, don't auto advance; choice will handle
            if currentPage.choice != nil { return }
            currentIndex += 1
            persist()
            checkEnding()
        } else {
            showEnding = true
            storage?.markCompleted(storyId: story.id)
        }
    }

    func prev() {
        if currentIndex > 0 { currentIndex -= 1; persist() }
    }

    func choose(option: StoryChoiceOption) {
        chosenPath.append(option.id)
        if let idx = pageIdToLinearIndex[option.nextPageId] {
            currentIndex = idx
        } else {
            // fallback next
            next()
        }
        persist()
    }

    private func persist() {
        storage?.updateProgress(storyId: story.id, pageIndex: currentIndex, totalPages: story.pages.count)
    }

    private func checkEnding() {
        if currentPage.isEnding { showEnding = true; storage?.markCompleted(storyId: story.id) }
    }

    // Auto play - does NOT toggle isAutoPlay itself; caller sets isAutoPlay
    func setAutoPlay(_ enabled: Bool) {
        isAutoPlay = enabled
        if enabled { startAuto() } else { stopAuto() }
    }

    func stopAuto() {
        autoTask?.cancel()
        autoTask = nil
    }

    private func startAuto() {
        autoTask?.cancel()
        autoTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                if Task.isCancelled { break }
                await MainActor.run {
                    // Pause on choice pages — user must pick
                    guard !self.showEnding else {
                        self.isAutoPlay = false
                        self.stopAuto()
                        return
                    }
                    if self.currentPage.choice == nil {
                        self.next()
                        if self.showEnding {
                            self.isAutoPlay = false
                            self.stopAuto()
                        }
                    } else {
                        // on choice page, keep waiting without looping aggressively
                    }
                }
            }
        }
    }

    func localizedText(_ page: StoryPage, lang: AppLanguage) -> String {
        lang == .telugu ? (page.textTe ?? page.text) : page.text
    }
    func localizedChoicePrompt(_ choice: StoryChoice, lang: AppLanguage) -> String {
        lang == .telugu ? (choice.promptTe ?? choice.prompt) : choice.prompt
    }
    func localizedOptionLabel(_ opt: StoryChoiceOption, lang: AppLanguage) -> String {
        lang == .telugu ? (opt.labelTe ?? opt.label) : opt.label
    }
}
