import SwiftUI
import Combine
import SwiftData

struct StoryDetailView: View {
    let story: Story
    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @StateObject private var vm: StoryDetailViewModel
    @State private var showReader = false

    init(story: Story) {
        self.story = story
        _vm = StateObject(wrappedValue: StoryDetailViewModel(story: story))
    }

    var body: some View {
        ZStack {
            AnimatedBackgroundView().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    cover
                    infoRow
                    actionButtons
                    descriptionSection
                    discoverSection
                    offlineBadge
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(story.localizedTitle(lang: appState.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $showReader) { StoryReaderView(story: story) }
        .onAppear { vm.inject(StorageService(context: context)) }
        .sheet(isPresented: $vm.showPDFShare) {
            if let url = vm.pdfURL { ShareSheet(url: url) }
        }
    }

    private var cover: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: story.coverGradient.compactMap { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 300).clipShape(RoundedRectangle(cornerRadius: 24))
            VStack(alignment: .leading, spacing: 6) {
                Text(story.coverEmoji).font(.system(size: 54))
                Text(story.localizedTitle(lang: appState.language)).font(.title.weight(.bold)).foregroundColor(.white)
                Text("\"\(story.localizedDescription(lang: appState.language))\"").font(.subheadline).foregroundColor(.white.opacity(0.85))
            }
            .padding(18)
        }
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.3), radius: 12)
    }

    private var infoRow: some View {
        HStack(spacing: 16) {
            Label(String(format: "%.1f", story.rating), systemImage: "star.fill").foregroundColor(.yellow)
            Label(story.readingTimeText, systemImage: "clock").foregroundColor(.white.opacity(0.8))
            Label("Ages \(story.ageRange)", systemImage: "person.fill").foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(story.category.emoji + " " + story.category.rawValue).font(.caption.weight(.bold)).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6).background(Color.white.opacity(0.15), in: Capsule())
        }
        .font(.caption).padding(.horizontal)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { showReader = true }) {
                Label("▶ Start Story", systemImage: "play.fill").frame(maxWidth: .infinity).padding().background(AppColors.gradientAccent, in: RoundedRectangle(cornerRadius: 16)).foregroundColor(.white).font(.headline)
            }
            HStack(spacing: 12) {
                Button(action: { withAnimation(.spring()) { vm.toggleFavorite() } }) {
                    Label(vm.isFavorite ? "Favorited" : "Add to Favorites", systemImage: vm.isFavorite ? "heart.fill" : "heart").frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12)).foregroundColor(.white)
                }
                Button(action: { vm.toggleOffline() }) {
                    Label(vm.isOffline ? "Offline ✓" : "Save Offline", systemImage: "arrow.down.circle").frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12)).foregroundColor(.white)
                }
            }
            Button("Create Storybook PDF") { vm.generatePDF(lang: appState.language) }.font(.subheadline.weight(.semibold)).foregroundColor(AppColors.accent)
        }
        .padding(.horizontal)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(story.localizedDescription(lang: appState.language)).foregroundColor(.white.opacity(0.85)).font(.body)
        }.padding(.horizontal)
    }

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What you'll discover").font(.headline).foregroundColor(.white).padding(.horizontal)
            VStack(spacing: 8) {
                ForEach(Array(zip(story.discoverItems, story.discoverEmojis)), id: \.0) { item, emoji in
                    HStack(spacing: 10) { Text(emoji); Text(item).foregroundColor(.white.opacity(0.9)).font(.subheadline); Spacer() }
                        .padding(10).background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
            }.padding(.horizontal)
        }
    }

    private var offlineBadge: some View {
        HStack {
            Image(systemName: vm.isOffline ? "checkmark.shield.fill" : "cloud")
            Text(vm.isOffline ? "Available Offline" : "Online")
        }.font(.caption).foregroundColor(.white.opacity(0.7))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [url], applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
