import SwiftUI
import Combine

struct NaturalVoiceSettingsView: View {
    @AppStorage("voicePersona") private var personaRaw = "Female"
    @AppStorage("useNaturalCloud") private var useNatural = false
    @AppStorage("openai_api_key") private var openAIKey = ""
    @AppStorage("sarvam_api_key") private var sarvamKey = ""
    @State private var showInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Natural Voice").font(.headline).foregroundColor(.white)
                Spacer()
                Button(action: { showInfo.toggle() }) { Image(systemName: "info.circle").foregroundColor(.white.opacity(0.7)) }
            }
            Text("Indian-accented, human-like voices — not robotic. Pick who tells the story.").font(.caption).foregroundColor(.white.opacity(0.7))

            // Persona
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VoicePersona.allCases) { p in
                        Button(action: { personaRaw = p.rawValue }) {
                            Text("\(p.emoji) \(p.rawValue)").font(.caption2.weight(.bold))
                                .foregroundColor(personaRaw == p.rawValue ? .black : .white)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(personaRaw == p.rawValue ? Color.white : Color.white.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }

            // Quality hint
            Label("Enhanced voices are much more natural than default. On iPhone go to Settings → Accessibility → Spoken Content → Voices → Download Enhanced (en-IN, te-IN).", systemImage: "waveform")
                .font(.caption2).foregroundColor(.white.opacity(0.6))

            Toggle(isOn: $useNatural) {
                Label("Ultra-Natural Cloud Voice (AI)", systemImage: "sparkles")
            }.tint(AppColors.accent).foregroundColor(.white)

            if useNatural {
                VStack(spacing: 8) {
                    SecureField("OpenAI API Key (for nova/shimmer natural)", text: $openAIKey)
                        .textFieldStyle(.roundedBorder).font(.caption)
                    SecureField("Sarvam AI Key (best for Telugu te-IN)", text: $sarvamKey)
                        .textFieldStyle(.roundedBorder).font(.caption)
                    Text("Without a key, the app uses enhanced local voices (already Indian-accented en-IN). Add a key for studio-quality natural.").font(.caption2).foregroundColor(.white.opacity(0.6))
                }.padding(10).background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }

            if showInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Female/Male/Kid/Grandma/Grandpa changes pitch & speed to sound like that person.").font(.caption2).foregroundColor(.white.opacity(0.8))
                    Text("• Telugu uses te-IN voice when available, slower pace for fluency.").font(.caption2).foregroundColor(.white.opacity(0.8))
                    Text("• Cloud voices (OpenAI TTS-1-HD / Sarvam Bulbul) sound studio-human.").font(.caption2).foregroundColor(.white.opacity(0.8))
                }.padding(8).background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14).background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}
