import SwiftUI
import Combine
import SwiftData

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = HomeViewModel()
    @Environment(\.modelContext) private var context
    @State private var selectedStory: Story?
    @State private var showDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView().ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        if let feat = vm.featured {
                            FeaturedCardView(story: feat) { selectedStory = feat; showDetail = true }
                                .padding(.horizontal)
                        }
                        if !vm.continueReading.isEmpty {
                            continueReadingSection
                        }
                        dailyStory
                        categorySection
                        storyGrid
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: $showDetail) {
                if let s = selectedStory {
                    StoryDetailView(story: s)
                }
            }
            .toolbar { ToolbarItem(placement: .principal) { Text(Constants.appName).font(.headline.weight(.bold)).foregroundColor(.white) } }
        }
        .task {
            let storage = StorageService(context: context)
            vm.inject(storage: storage)
            await vm.load()
        }
        .refreshable { await vm.load() }
        .overlay { if vm.isLoading { ProgressView("✨ Preparing your adventure...").tint(.white).foregroundColor(.white).padding().background(.ultraThinMaterial, in: Capsule()) } }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting()).font(.title2.weight(.bold)).foregroundColor(.white)
            Text("Where shall we travel today?").font(.headline).foregroundColor(.white.opacity(0.7))
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.6))
                TextField("Search space, animals...", text: $vm.searchText).foregroundColor(.white)
            }
            .padding(10).background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private var continueReadingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Continue Your Adventure").font(.headline).foregroundColor(.white).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(vm.continueReading, id: \.0.id) { pair in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Text(pair.0.coverEmoji).font(.title)
                                VStack(alignment: .leading) {
                                    Text(pair.0.title).font(.subheadline.weight(.semibold)).foregroundColor(.white).lineLimit(1)
                                    ProgressView(value: pair.1.progress).tint(AppColors.accent).frame(width: 90)
                                    Text("\(Int(pair.1.progress*100))%").font(.caption2).foregroundColor(.white.opacity(0.7))
                                }
                            }
                            Button("Continue Reading") { selectedStory = pair.0; showDetail = true }
                                .font(.caption.weight(.bold)).foregroundColor(AppColors.primary)
                                .padding(.horizontal, 12).padding(.vertical, 6).background(Color.white, in: Capsule())
                        }
                        .padding(14).background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
                    }
                }.padding(.horizontal)
            }
        }
    }

    private var dailyStory: some View {
        Group {
            if let sod = vm.storyOfDay {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Story of the Day", systemImage: "sparkles").font(.headline).foregroundColor(AppColors.accent).padding(.horizontal)
                    HStack(spacing: 14) {
                        Text(sod.coverEmoji).font(.system(size: 50))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(sod.title).font(.headline).foregroundColor(.white)
                            Text("Ready for today's adventure?").font(.caption).foregroundColor(.white.opacity(0.7))
                            Button("Start Story") { selectedStory = sod; showDetail = true }
                                .font(.caption.weight(.bold)).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 6).background(AppColors.gradientAccent, in: Capsule())
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .padding(.horizontal)
                    .shadow(color: AppColors.accent.opacity(0.2), radius: 12)
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Explore Stories").font(.headline).foregroundColor(.white).padding(.horizontal)
            CategoryChipsRow(selected: nil) { _ in }
        }
    }

    private var storyGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Popular Adventures").font(.headline).foregroundColor(.white).padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(vm.filteredStories) { story in
                    StoryCardView(story: story, isFavorite: vm.isFavorite(story), progress: vm.progress(for: story)) {
                        let s = StorageService(context: context)
                        s.toggleFavorite(storyId: story.id)
                        Task { await vm.load() }
                    }
                    .onTapGesture { selectedStory = story; showDetail = true }
                }
            }
            .padding(.horizontal)
        }
    }

    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = (try? context.fetch(FetchDescriptor<AppUserProfile>()).first?.name) ?? "little explorer"
        if hour < 12 { return "Good morning, \(name)! 👋" }
        if hour < 18 { return "Good afternoon, \(name)! 👋" }
        return "Good evening, \(name)! 👋"
    }
}
