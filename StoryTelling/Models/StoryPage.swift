import Foundation
import Combine

struct StoryPage: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let index: Int
    let text: String
    let textTe: String?
    let illustrationName: String
    let narrationText: String
    let narrationTextTe: String? = nil
    let choice: StoryChoice?
    let isEnding: Bool

    var localizedText: String {
        // language handled in ViewModel
        text
    }
    func narration(for lang: AppLanguage) -> String {
        if lang == .telugu, let te = narrationTextTe, !te.isEmpty { return te }
        if lang == .telugu, let te = textTe, !te.isEmpty { return te }
        return narrationText
    }
}

struct StoryChoice: Codable, Equatable, Hashable {
    let prompt: String
    let promptTe: String?
    let options: [StoryChoiceOption]
}

struct StoryChoiceOption: Codable, Equatable, Hashable, Identifiable {
    let id: String
    let label: String
    let labelTe: String?
    let emoji: String
    let nextPageId: String
}

struct StoryEnding: Codable, Equatable, Hashable {
    let title: String
    let message: String
    let emoji: String
}
