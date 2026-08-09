import SwiftUI
import Combine
import SwiftData

struct FavoritesView: View {
    @StateObject private var vm = FavoritesViewModel()
    @Environment(\.modelContext) private var context
    @State private var selected: Story?
    @State private var showDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView().ignoresSafeArea()
                if vm.stories.isEmpty {
                    VStack(spacing: 14) {
                        Text("❤️").font(.system(size: 60))
                        Text("Your adventure shelf is waiting for its first story!").font(.headline).foregroundColor(.white).multilineTextAlignment(.center).padding(.horizontal)
                        Text("Tap the heart on any story to save it here.").font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(vm.stories) { story in
                                StoryCardView(story: story, isFavorite: true) { vm.remove(story) }
                                    .onTapGesture { selected = story; showDetail = true }
                            }
                        }.padding()
                    }
                }
            }
            .navigationTitle("My Collection ❤️")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(isPresented: $showDetail) { if let s = selected { StoryDetailView(story: s) } }
        }
        .task {
            vm.inject(StorageService(context: context))
            await vm.load()
        }
        .onAppear { vm.refresh() }
    }
}
