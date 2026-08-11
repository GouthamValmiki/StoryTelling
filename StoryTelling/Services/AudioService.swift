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

    // Moderate rates make the built-in voice substantially easier to understand.
    // Do not simulate people with extreme pitch changes: that is a common cause of
    // the synthetic/robotic sound users notice.
    var rateFactor: Float {
        switch self {
        case .female, .male: return 0.46
        case .kid: return 0.44
        case .grandma, .grandpa: return 0.42
        }
    }

    /// Select a downloaded Premium/Enhanced voice before the compact default voice.
    func voice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == languageCode }
        guard !voices.isEmpty else { return AVSpeechSynthesisVoice(language: languageCode) }

        let preferredQuality = voices.sorted { qualityScore($0) > qualityScore($1) }
        let genderTerms: [String]
        switch self {
        case .male, .grandpa: genderTerms = ["aaron", "daniel", "male", "rishi", "rocko"]
        case .female, .grandma, .kid: genderTerms = ["samantha", "karen", "female", "priya", "rishi"]
        }
        return preferredQuality.first { voice in
            let name = voice.name.lowercased()
            return genderTerms.contains { name.contains($0) }
        } ?? preferredQuality.first
    }

    private func qualityScore(_ voice: AVSpeechSynthesisVoice) -> Int {
        switch voice.quality {
        case .premium: return 3
        case .enhanced: return 2
        default: return 1
        }
    }
}

@MainActor
final class AudioService: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentRate: Float = 1.0
    @Published var highlightedRange: NSRange?
    @Published var persona: VoicePersona { didSet { UserDefaults.standard.set(persona.rawValue, forKey: "voicePersona") } }
    @Published var useNaturalCloud = UserDefaults.standard.bool(forKey: "useNaturalCloud")
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var currentText = ""
    private var currentLangCode = "en-US"
    private var cloudTask: Task<Void, Never>?

    override init() {
        persona = UserDefaults.standard.string(forKey: "voicePersona").flatMap(VoicePersona.init(rawValue:)) ?? .female
        if UserDefaults.standard.object(forKey: "useNaturalCloud") == nil {
            UserDefaults.standard.set(true, forKey: "useNaturalCloud")
            useNaturalCloud = true
        }
        super.init()
        synthesizer.delegate = self
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
        try? AVAudioSession.sharedInstance().setActive(true)
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
    }

    /// Uses a studio-quality cloud narrator when configured, then a downloaded
    /// Premium/Enhanced iOS voice as a private, offline fallback.
    func speak(_ text: String, language: String = "en-US", rate: Float? = nil) {
        stop()
        currentText = text
        currentLangCode = language
        if useNaturalCloud {
            cloudTask = Task { [weak self] in
                do {
                    let persona = await MainActor.run { self?.persona ?? .female }
                    let url = try await NaturalTTSService.shared.synthesize(text: text, language: language, persona: persona)
                    guard !Task.isCancelled else { return }
                    await MainActor.run { self?.playCloudFile(url: url) }
                } catch is CancellationError {
                    // A new page was selected; never start stale narration.
                } catch {
                    await MainActor.run { self?.speakLocal(text, language: language, rate: rate) }
                }
            }
            isPlaying = true
        } else {
            speakLocal(text, language: language, rate: rate)
        }
    }

    private func speakLocal(_ text: String, language: String, rate: Float?) {
        let hasTelugu = AVSpeechSynthesisVoice.speechVoices().contains { $0.language == "te-IN" }
        let effectiveLanguage = language == "te-IN" && !hasTelugu ? "en-IN" : language
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = persona.voice(for: effectiveLanguage) ?? AVSpeechSynthesisVoice(language: effectiveLanguage)
        utterance.rate = (rate ?? persona.rateFactor) * currentRate * (effectiveLanguage == "te-IN" ? 0.84 : 1)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1
        utterance.preUtteranceDelay = 0.18
        utterance.postUtteranceDelay = 0.16
        isPlaying = true
        synthesizer.speak(utterance)
    }

    private func playCloudFile(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            speakLocal(currentText, language: currentLangCode, rate: nil)
        }
    }

    func setRate(_ rate: Float) { currentRate = rate; if isPlaying { speak(currentText, language: currentLangCode) } }
    func setPersona(_ value: VoicePersona) { persona = value; if isPlaying { speak(currentText, language: currentLangCode) } }
    func setNatural(_ enabled: Bool) { useNaturalCloud = enabled; UserDefaults.standard.set(enabled, forKey: "useNaturalCloud") }
    func stop() { cloudTask?.cancel(); cloudTask = nil; synthesizer.stopSpeaking(at: .immediate); audioPlayer?.stop(); audioPlayer = nil; isPlaying = false; highlightedRange = nil }
    func pause() { synthesizer.pauseSpeaking(at: .word); audioPlayer?.pause(); isPlaying = false }
    func resume() { if audioPlayer != nil { audioPlayer?.play(); isPlaying = true } else { synthesizer.continueSpeaking(); isPlaying = true } }
    func toggle(text: String, lang: AppLanguage) {
        if isPlaying { pause() }
        else if synthesizer.isPaused || audioPlayer != nil { resume() }
        else { speak(text, language: lang == .telugu ? "te-IN" : "en-IN") }
    }
}

extension AudioService: AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString range: NSRange, utterance: AVSpeechUtterance) { Task { @MainActor in self.highlightedRange = range } }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { Task { @MainActor in self.isPlaying = false; self.highlightedRange = nil } }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { Task { @MainActor in self.isPlaying = false; self.highlightedRange = nil } }
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { Task { @MainActor in if self.audioPlayer === player { self.isPlaying = false; self.highlightedRange = nil } } }
}
