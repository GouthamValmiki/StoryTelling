import Foundation
import Combine
import AVFoundation

@MainActor
final class AudioService: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentRate: Float = 1.0
    @Published var highlightedRange: NSRange?

    private var synthesizer = AVSpeechSynthesizer()
    private var currentText: String = ""

    override init() {
        super.init()
        synthesizer.delegate = self
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
    }

    func speak(_ text: String, language: String = "en-US", rate: Float = 0.5) {
        stop()
        currentText = text
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate * currentRate // base 0.5
        utterance.pitchMultiplier = 1.0
        isPlaying = true
        synthesizer.speak(utterance)
    }

    func setRate(_ rate: Float) {
        currentRate = rate
        if isPlaying {
            // restart with new rate
            let txt = currentText
            speak(txt, rate: 0.5)
        }
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
            let code = lang == .telugu ? "te-IN" : "en-US"
            speak(text, language: code)
        }
    }
}

extension AudioService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString range: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.highlightedRange = range
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = false
            self.highlightedRange = nil
        }
    }
}
