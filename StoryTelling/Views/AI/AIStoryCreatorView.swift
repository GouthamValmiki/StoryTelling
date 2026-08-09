import SwiftUI
import Combine

struct AIStoryCreatorView: View {
    @State private var prompt = ""
    @State private var ageRange = "5-8"
    @State private var isGenerating = false
    @State private var generated: Story?
    @State private var showReader = false
    @EnvironmentObject var appState: AppState

    private let ai: any AIStoryServiceProtocol = AIStoryService()

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        inputCard
                        if isGenerating { ProgressView("✨ AI is writing your story...").tint(.white).foregroundColor(.white) }
                        if let story = generated {
                            StoryCardView(story: story).onTapGesture { showReader = true }
                            Button("Read Now →") { showReader = true }.buttonStyle(.borderedProminent).tint(AppColors.primary)
                        }
                        tips
                    }.padding()
                }
            }
            .navigationTitle("AI Magic Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(isPresented: $showReader) {
                if let s = generated { StoryReaderView(story: s) }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("✨ Create with AI").font(.title2.weight(.bold)).foregroundColor(.white)
            Text("Tell AI what story you want — daily life, village, school, family — in English or Telugu.").font(.caption).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
        }.padding(14).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What should the story be about?").font(.headline).foregroundColor(.white)
            TextField("e.g., A girl who helps Amma cook pongal and learns to share", text: $prompt, axis: .vertical)
                .lineLimit(3...6).padding(10).background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12)).foregroundColor(.white)
            HStack {
                Text("Age").foregroundColor(.white.opacity(0.8)).font(.caption)
                Picker("Age", selection: $ageRange) {
                    Text("3-6").tag("3-6"); Text("5-8").tag("5-8"); Text("7-10").tag("7-10")
                }.pickerStyle(.segmented).frame(width: 180)
                Spacer()
            }
            Button(action: generate) {
                Label(isGenerating ? "Generating..." : "Generate Story ✨", systemImage: "wand.and.stars").frame(maxWidth: .infinity).padding().background(AppColors.gradientAccent, in: RoundedRectangle(cornerRadius: 14)).foregroundColor(.white).fontWeight(.bold)
            }.disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty || isGenerating)
            if !(ai as? AIStoryService)?.isConfigured() ?? true {
                Text("Tip: Offline mode — generates a beautiful realistic daily-life story instantly. Add OPENAI_API_KEY for cloud AI.").font(.caption2).foregroundColor(.white.opacity(0.6))
            }
        }.padding(14).background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var tips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try:").font(.caption.weight(.bold)).foregroundColor(.white.opacity(0.8))
            ForEach(["My friend and I share tiffin at school","Grandpa's field and a small help","A village festival with colours","Learning to say sorry"], id: \.self) { ex in
                Button(ex) { prompt = ex }.font(.caption).foregroundColor(AppColors.accent)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func generate() {
        isGenerating = true
        Task {
            do {
                let story = try await ai.generateStory(prompt: prompt, language: appState.language, ageRange: ageRange)
                await MainActor.run { generated = story; isGenerating = false }
            } catch {
                await MainActor.run { isGenerating = false }
            }
        }
    }
}
