import Foundation
import Combine
import AVFoundation

enum VoicePersona: String, CaseIterable, Identifiable {
    case female = "Female"
    case male = "Male"
    case kid = "Kid"
    case grandma = "Grandma"
    case grandpa = "Grandpa"
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .female: return "👩"
        case .male: return "👨"
        case .kid: return "🧒"
        case .grandma: return "👵"
        case .grandpa: return "👴"
        }
    }
    var pitch: Float {
        switch self {
        case .female: return 1.15
        case .male: return 0.95
        case .kid: return 1.35
        case .grandma: return 1.05
        case .grandpa: return 0.85
        }
    }
    var rateFactor: Float {
        switch self {
        case .female: return 0.50
        case .male: return 0.48
        case .kid: return 0.45
        case .grandma: return 0.38
        case .grandpa: return 0.40
        }
    }
    func voice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        // Prefer enhanced/comfort voice if available
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == languageCode }
        if voices.isEmpty { return AVSpeechSynthesisVoice(language: languageCode) }
        // Map persona to voice gender approximation
        switch self {
        case .female, .grandma:
            return voices.first(where: { $0.name.lowercased().contains("female") || $0.name.lowercased().contains("samantha") }) ?? voices.first
        case .male, .grandpa:
            return voices.first(where: { $0.name.lowercased().contains("male") || $0.name.lowercased().contains("aaron") }) ?? voices.first
        case .kid:
            return voices.first // pitch will simulate kid
        }
    }
}

@MainActor
final class AudioService: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentRate: Float = 1.0
    @Published var highlightedRange: NSRange?
    @Published var persona: VoicePersona {
        didSet { UserDefaults.standard.set(persona.rawValue, forKey: "voicePersona") }
    }
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []

    private var synthesizer = AVSpeechSynthesizer()
    private var currentText: String = ""
    private var currentLangCode: String = "en-US"

    override init() {
        let saved = UserDefaults.standard.string(forKey: "voicePersona").flatMap { VoicePersona(rawValue: $0) } ?? .female
        self.persona = saved
        super.init()
        synthesizer.delegate = self
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
    }

    func speak(_ text: String, language: String = "en-US", rate: Float? = nil) {
        stop()
        currentText = text
        currentLangCode = language
        // Telugu fallback: if te-IN voice not available on device, use en-US with transliterated clarity
        let hasTelugu = AVSpeechSynthesisVoice.speechVoices().contains { $0.language == "te-IN" }
        let effectiveLang = (language == "te-IN" && !hasTelugu) ? "en-US" : language
        let baseRate = rate ?? persona.rateFactor

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = persona.voice(for: effectiveLang) ?? AVSpeechSynthesisVoice(language: effectiveLang)
        // slower, clearer for kids — extra slow for Telugu for fluency
        let langFactor: Float = (effectiveLang == "te-IN") ? 0.82 : 1.0
        utterance.rate = baseRate * currentRate * langFactor
        utterance.pitchMultiplier = persona.pitch
        utterance.volume = 0.95
        utterance.preUtteranceDelay = 0.15
        isPlaying = true
        synthesizer.speak(utterance)
    }

    func setRate(_ rate: Float) {
        currentRate = rate
        if isPlaying {
            speak(currentText, language: currentLangCode)
        }
    }

    func setPersona(_ p: VoicePersona) {
        persona = p
        if isPlaying { speak(currentText, language: currentLangCode) }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        highlightedRange = nil
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
        isPlaying = false
    }

    func resume() {
        synthesizer.continueSpeaking()
        isPlaying = true
    }

    func toggle(text: String, lang: AppLanguage) {
        if isPlaying { pause() }
        else if synthesizer.isPaused { resume() }
        else {
            let hasTe = AVSpeechSynthesisVoice.speechVoices().contains { $0.language == "te-IN" }
            let code: String
            if lang == .telugu && hasTe { code = "te-IN" }
            else if lang == .telugu && !hasTe { code = "te-IN" } // will fallback inside speak
            else { code = "en-US" }
            speak(text, language: code)
        }
    }
}

extension AudioService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString range: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in self.highlightedRange = range }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isPlaying = false; self.highlightedRange = nil }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isPlaying = false; self.highlightedRange = nil }
    }
}
