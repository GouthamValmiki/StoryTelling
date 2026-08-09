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
        case .female: return 1.08
        case .male: return 0.92
        case .kid: return 1.28
        case .grandma: return 1.02
        case .grandpa: return 0.82
        }
    }
    var rateFactor: Float {
        switch self {
        case .female: return 0.50
        case .male: return 0.48
        case .kid: return 0.44
        case .grandma: return 0.36
        case .grandpa: return 0.38
        }
    }
    /// Pick the most natural enhanced voice on device for this persona
    func voice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        let all = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == languageCode }
        if all.isEmpty { return AVSpeechSynthesisVoice(language: languageCode) }
        // Prefer enhanced quality if available (iOS 16+ voices are much more natural)
        let enhanced = all.filter { $0.quality == .enhanced }
        let pool = enhanced.isEmpty ? all : enhanced
        switch self {
        case .female, .grandma:
            return pool.first(where: { $0.name.lowercased().contains("female") || $0.name.lowercased().contains("samantha") || $0.name.lowercased().contains("karen") || $0.name.lowercased().contains("premium") }) ?? pool.first
        case .male, .grandpa:
            return pool.first(where: { $0.name.lowercased().contains("aaron") || $0.name.lowercased().contains("daniel") || $0.name.lowercased().contains("male") }) ?? pool.first
        case .kid:
            return pool.first
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
    @Published var useNaturalCloud = UserDefaults.standard.bool(forKey: "useNaturalCloud")
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []

    private var synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var currentText: String = ""
    private var currentLangCode: String = "en-US"
    private var cloudTask: Task<Void, Never>?

    override init() {
        let saved = UserDefaults.standard.string(forKey: "voicePersona").flatMap { VoicePersona(rawValue: $0) } ?? .female
        self.persona = saved
        // Default to natural cloud ON (as requested: Sarvam for Telugu, OpenAI for English)
        if UserDefaults.standard.object(forKey: "useNaturalCloud") == nil {
            UserDefaults.standard.set(true, forKey: "useNaturalCloud")
            self.useNaturalCloud = true
        }
        super.init()
        synthesizer.delegate = self
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
        try? AVAudioSession.sharedInstance().setActive(true)
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
    }

    /// Public entry — tries natural cloud first if enabled, falls back to enhanced local
    func speak(_ text: String, language: String = "en-US", rate: Float? = nil) {
        stop()
        currentText = text
        currentLangCode = language

        // If natural cloud enabled and key exists, try cloud async
        if useNaturalCloud {
            cloudTask?.cancel()
            cloudTask = Task { [weak self] in
                do {
                    let persona = await MainActor.run { self?.persona ?? .female }
                    let url = try await NaturalTTSService.shared.synthesize(text: text, language: language, persona: persona)
                    await MainActor.run { self?.playCloudFile(url: url) }
                    return
                } catch {
                    // Cloud failed or offline → fallback to local enhanced
                    await MainActor.run { self?.speakLocal( text, language: language, rate: rate) }
                }
            }
            // Show playing immediately
            isPlaying = true
            return
        }
        speakLocal( text, language: language, rate: rate)
    }

    private func speakLocal(_ text: String, language: String, rate: Float?) {
        let hasTelugu = AVSpeechSynthesisVoice.speechVoices().contains { $0.language == "te-IN" }
        let effectiveLang = (language == "te-IN" && !hasTelugu) ? "en-IN" : language // en-IN accent more natural for India
        let baseRate = rate ?? persona.rateFactor
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = persona.voice(for: effectiveLang) ?? AVSpeechSynthesisVoice(language: effectiveLang)
        let langFactor: Float = (effectiveLang == "te-IN") ? 0.80 : 1.0
        utterance.rate = baseRate * currentRate * langFactor
        utterance.pitchMultiplier = persona.pitch
        utterance.volume = 0.98
        utterance.preUtteranceDelay = 0.12
        utterance.postUtteranceDelay = 0.1
        isPlaying = true
        synthesizer.speak(utterance)
    }

    private func playCloudFile(url: URL) {
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            // isPlaying will be cleared when player stops via delegate timer
            // Simple: mark playing and auto-clear after duration
            if let duration = audioPlayer?.duration {
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000) + 300_000_000)
                    await MainActor.run { self?.isPlaying = false }
                }
            }
        } catch {
            speakLocal( currentText, language: currentLangCode, rate: nil)
        }
    }

    func setRate(_ rate: Float) {
        currentRate = rate
        if isPlaying { speak(currentText, language: currentLangCode) }
    }
    func setPersona(_ p: VoicePersona) {
        persona = p
        if isPlaying { speak(currentText, language: currentLangCode) }
    }
    func setNatural(_ enabled: Bool) {
        useNaturalCloud = enabled
        UserDefaults.standard.set(enabled, forKey: "useNaturalCloud")
    }
    func stop() {
        cloudTask?.cancel()
        cloudTask = nil
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        highlightedRange = nil
    }
    func pause() {
        synthesizer.pauseSpeaking(at: .word)
        audioPlayer?.pause()
        isPlaying = false
    }
    func resume() {
        if audioPlayer != nil { audioPlayer?.play(); isPlaying = true }
        else { synthesizer.continueSpeaking(); isPlaying = true }
    }
    func toggle(text: String, lang: AppLanguage) {
        if isPlaying { pause() }
        else if synthesizer.isPaused || audioPlayer?.isPlaying == false { resume() }
        else {
            let code = lang == .telugu ? "te-IN" : "en-IN" // en-IN for natural Indian English
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
