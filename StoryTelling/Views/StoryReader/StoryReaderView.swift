import SwiftUI
import Combine
import SwiftData

struct StoryReaderView: View {
    let story: Story
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @StateObject private var vm: ReaderViewModel
    @StateObject private var audio = AudioService()

    init(story: Story) {
        self.story = story
        _vm = StateObject(wrappedValue: ReaderViewModel(story: story))
    }

    var body: some View {
        ZStack {
            // Full screen illustration gradient
            LinearGradient(colors: story.coverGradient.compactMap { Color(hex: $0) }.map { $0.opacity(0.9) }, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                topBar
                progressBar
                Spacer()
                storyCard
                Spacer()
                controls
                autoToggle
            }
            .padding()
        }
        .onAppear { vm.inject(StorageService(context: context)) }
        .gesture(DragGesture(minimumDistance: 40).onEnded { v in
            if v.translation.width < -30 { vm.next() }
            if v.translation.width > 30 { vm.prev() }
        })
        .overlay { if vm.showEnding { endingOverlay } }
    }

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) { Image(systemName: "xmark").foregroundColor(.white).padding(8).background(Color.black.opacity(0.3), in: Circle()) }
            Spacer()
            Text("Page \(vm.currentIndex+1) / \(story.pages.count)").font(.caption.weight(.bold)).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6).background(Color.black.opacity(0.25), in: Capsule())
            Spacer()
            Button(action: { audio.stop(); dismiss() }) { Image(systemName: "book.closed").foregroundColor(.white) }
        }
    }

    private var progressBar: some View {
        ProgressView(value: vm.progress).tint(.white).background(Color.white.opacity(0.2))
    }

    private var storyCard: some View {
        let page = vm.currentPage
        let text = vm.localizedText(page, lang: appState.language)
        return VStack(spacing: 14) {
            Text(story.coverEmoji).font(.system(size: 60)).shadow(radius: 8)
            // Highlighted text
            highlightedText(text: text)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                .onTapGesture {
                    audio.toggle(text: vm.localizedNarration(page, lang: appState.language), lang: appState.language)
                }
            if let choice = page.choice {
                VStack(spacing: 10) {
                    Text(vm.localizedChoicePrompt(choice, lang: appState.language)).font(.headline).foregroundColor(.white)
                    ForEach(choice.options) { opt in
                        Button(action: { vm.choose(option: opt); audio.stop() }) {
                            HStack { Text(opt.emoji); Text(vm.localizedOptionLabel(opt, lang: appState.language)).fontWeight(.semibold); Spacer(); Image(systemName: "chevron.right") }
                                .foregroundColor(.white).padding().background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.top, 6)
            }
        }
        .animation(.easeInOut, value: vm.currentIndex)
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }

    @ViewBuilder
    private func highlightedText(text: String) -> some View {
        if audio.isPlaying, let range = audio.highlightedRange, range.location < text.count {
            let ns = text as NSString
            let before = ns.substring(to: range.location)
            let highlighted = ns.substring(with: range)
            let after = range.location + range.length < ns.length ? ns.substring(from: range.location+range.length) : ""
            Text(before) + Text(highlighted).foregroundColor(AppColors.accent).bold() + Text(after)
        } else {
            Text(text)
        }
    }

    private var controls: some View {
        HStack(spacing: 18) {
            Button(action: { vm.prev(); audio.stop() }) { Image(systemName: "chevron.left.circle.fill").font(.largeTitle).foregroundColor(.white.opacity(vm.canGoPrev ? 1 : 0.3)) }.disabled(!vm.canGoPrev)
            Button(action: { audio.toggle(text: vm.localizedNarration(vm.currentPage, lang: appState.language), lang: appState.language) }) {
                Image(systemName: audio.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 56)).foregroundColor(.white)
            }
            .overlay { if audio.isPlaying { Text("〰️〰️〰️").font(.caption).offset(y: 40).foregroundColor(.white.opacity(0.8)) } }
            Button(action: { vm.next(); audio.stop() }) { Image(systemName: "chevron.right.circle.fill").font(.largeTitle).foregroundColor(.white.opacity(vm.canGoNext ? 1 : 0.5)) }
        }
    }

    private var autoToggle: some View {
        VStack(spacing: 8) {
            Toggle(isOn: Binding(
                get: { vm.isAutoPlay },
                set: { newVal in
                    vm.setAutoPlay(newVal)
                    if newVal {
                        audio.speak(vm.localizedNarration(vm.currentPage, lang: appState.language), language: appState.language == .telugu ? "te-IN" : "en-US")
                    } else {
                        audio.stop()
                    }
                }
            )) { Label("Read to Me", systemImage: "headphones") }.tint(AppColors.accent).foregroundColor(.white)
                .onChange(of: vm.currentIndex) { _, _ in
                    if vm.isAutoPlay {
                        audio.speak(vm.localizedNarration(vm.currentPage, lang: appState.language), language: appState.language == .telugu ? "te-IN" : "en-US")
                    }
                }
                .onDisappear { vm.stopAuto(); audio.stop() }
            // Voice persona picker — Male/Female/Kid/Grandma/Grandpa
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VoicePersona.allCases) { p in
                        Button(action: { audio.setPersona(p) }) {
                            Text("\(p.emoji) \(p.rawValue)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(audio.persona == p ? .black : .white)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(audio.persona == p ? Color.white : Color.white.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
            HStack(spacing: 8) {
                Text("Speed").font(.caption).foregroundColor(.white.opacity(0.8))
                ForEach([0.75,1.0,1.25,1.5], id: \.self) { s in
                    Button("\(s, specifier: "%.2g")x") { audio.setRate(Float(s)) }
                        .font(.caption2.weight(.bold)).foregroundColor(audio.currentRate==Float(s) ? .black : .white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(audio.currentRate==Float(s) ? Color.white : Color.white.opacity(0.15), in: Capsule())
                }
            }
        }
        .padding(10).background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
    }

    private var endingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("✨ 🌙 🦋").font(.largeTitle)
                Text("And they lived happily ever after...").font(.title3.weight(.bold)).foregroundColor(.white).multilineTextAlignment(.center)
                Text("⭐ You completed the adventure!").foregroundColor(AppColors.accent)
                HStack(spacing: 8) {
                    Label("📖 \(story.pages.count) pages", systemImage: "book").font(.caption).foregroundColor(.white.opacity(0.8))
                    Label("⏱ \(story.durationMinutes) min", systemImage: "clock").font(.caption).foregroundColor(.white.opacity(0.8))
                }
                HStack(spacing: 12) {
                    Button("Read Again") { vm.showEnding = false; vm.currentIndex = 0 }.padding(.horizontal, 18).padding(.vertical, 10).background(Color.white, in: Capsule()).foregroundColor(AppColors.primary).fontWeight(.bold)
                    Button("Explore Another Story") { audio.stop(); dismiss() }.padding(.horizontal, 18).padding(.vertical, 10).background(AppColors.gradientAccent, in: Capsule()).foregroundColor(.white).fontWeight(.bold)
                }
                Button("Add to Favorites ❤️") {
                    StorageService(context: context).toggleFavorite(storyId: story.id)
                }.foregroundColor(.white).font(.caption)
            }
            .padding(24).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24)).padding()
        }
    }
}
