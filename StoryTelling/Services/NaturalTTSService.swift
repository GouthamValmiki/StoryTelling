import Foundation
import AVFoundation

/// Natural, human-like Indian voices via cloud TTS.
/// Works offline with enhanced local voice if no API key is set.
/// Architecture ready for Sarvam / OpenAI / Google WaveNet / ElevenLabs.
actor NaturalTTSService {
    static let shared = NaturalTTSService()

    enum Provider {
        case localEnhanced   // AVSpeechSynthesizer enhanced (free, offline)
        case openAI          // OpenAI tts-1 -> very natural, needs OPENAI_API_KEY
        case sarvam          // Sarvam AI -> best for Telugu + Indian English
    }

    private var audioPlayer: AVAudioPlayer?
    private var cache: [String: URL] = [:]

    func currentProvider() -> Provider {
        // Default routing: Sarvam for Telugu, OpenAI for English — as requested
        return provider(for: "en-IN")
    }
    func provider(for language: String) -> Provider {
        let hasOpenAI = !(UserDefaults.standard.string(forKey: "openai_api_key") ?? "").isEmpty
        let hasSarvam = !(UserDefaults.standard.string(forKey: "sarvam_api_key") ?? "").isEmpty
        if language == "te-IN" {
            if hasSarvam { return .sarvam }
            if hasOpenAI { return .openAI } // fallback to OpenAI if Sarvam not set
            return .localEnhanced
        } else {
            // English / en-IN
            if hasOpenAI { return .openAI }
            if hasSarvam { return .sarvam } // Sarvam also does en-IN well
            return .localEnhanced
        }
    }

    // Map persona + language to cloud voice name
    func cloudVoiceName(for persona: VoicePersona, language: String) -> String {
        // OpenAI voices: alloy, echo, fable, onyx, nova, shimmer — nova/shimmer most natural Indian-friendly
        // Sarvam: anushka (female), manisha etc.
        switch (persona, language) {
        case (.female, "te-IN"): return "anushka" // Sarvam
        case (.male, "te-IN"): return "abhilash"
        case (.kid, "te-IN"): return "anushka"
        case (.grandma, "te-IN"): return "manisha"
        case (.grandpa, "te-IN"): return "vidya" // placeholder
        case (.female, _): return "nova"
        case (.male, _): return "onyx"
        case (.kid, _): return "shimmer"
        case (.grandma, _): return "nova"
        case (.grandpa, _): return "onyx"
        }
    }

    func synthesize(text: String, language: String, persona: VoicePersona) async throws -> URL {
        let cacheKey = "\(language)_\(persona.rawValue)_\(text.hashValue)"
        if let cached = cache[cacheKey], FileManager.default.fileExists(atPath: cached.path) {
            return cached
        }

        switch provider(for: language) {
        case .openAI:
            return try await synthesizeOpenAI(text: text, language: language, persona: persona, cacheKey: cacheKey)
        case .sarvam:
            return try await synthesizeSarvam(text: text, language: language, persona: persona, cacheKey: cacheKey)
        case .localEnhanced:
            throw URLError(.notConnectedToInternet) // caller will fallback to AVSpeechSynthesizer enhanced
        }
    }

    private func synthesizeOpenAI(text: String, language: String, persona: VoicePersona, cacheKey: String) async throws -> URL {
        guard let apiKey = UserDefaults.standard.string(forKey: "openai_api_key"), !apiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/speech")!)
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // Map to OpenAI voice: nova = warm female Indian-friendly, alloy = neutral
        let voice = cloudVoiceName(for: persona, language: language) // nova/onyx etc
        let openAIVoice = ["nova","shimmer","alloy","echo","fable","onyx"].contains(voice) ? voice : "nova"
        let body: [String: Any] = [
            "model": "tts-1", // or tts-1-hd for highest naturalness
            "input": text,
            "voice": openAIVoice,
            "response_format": "mp3",
            "speed": language == "te-IN" ? 0.92 : 0.95
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(cacheKey).mp3")
        try data.write(to: url)
        cache[cacheKey] = url
        return url
    }

    private func synthesizeSarvam(text: String, language: String, persona: VoicePersona, cacheKey: String) async throws -> URL {
        guard let apiKey = UserDefaults.standard.string(forKey: "sarvam_api_key"), !apiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        // Sarvam AI Bulk TTS: https://api.sarvam.ai/text-to-speech
        var req = URLRequest(url: URL(string: "https://api.sarvam.ai/text-to-speech")!)
        req.httpMethod = "POST"
        req.addValue("api-subscription-key \(apiKey)", forHTTPHeaderField: "api-subscription-key")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let targetLang = language == "te-IN" ? "te-IN" : "en-IN"
        let speaker = cloudVoiceName(for: persona, language: language)
        let body: [String: Any] = [
            "inputs": [text],
            "target_language_code": targetLang,
            "speaker": speaker,
            "pitch": 0,
            "pace": language == "te-IN" ? 0.95 : 1.0,
            "loudness": 1.0,
            "speech_sample_rate": 22050,
            "enable_preprocessing": true,
            "model": "bulbul:v1"
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        // Sarvam returns base64 audios in JSON
        if let json = try JSONSerialization.jsonObject(with: data) as? [String:Any],
           let audios = json["audios"] as? [String], let b64 = audios.first,
           let audioData = Data(base64Encoded: b64) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(cacheKey).wav")
            try audioData.write(to: url)
            cache[cacheKey] = url
            return url
        }
        throw URLError(.cannotParseResponse)
    }
}
