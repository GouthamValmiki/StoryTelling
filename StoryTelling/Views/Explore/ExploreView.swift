import SwiftUI
import Combine
import SwiftData

struct ExploreView: View {
    @StateObject private var vm = ExploreViewModel()
    @Environment(\.modelContext) private var context
    @State private var selected: Story?
    @State private var showDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView().ignoresSafeArea()
                VStack(spacing: 14) {
                    searchBar
                    CategoryChipsRow(selected: vm.selectedCategory) { cat in vm.selectedCategory = cat }
                    suggestedRow
                    storyList
                }
                .padding(.top)
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(isPresented: $showDetail) { if let s = selected { StoryDetailView(story: s) } }
        }
        .task { await vm.load() }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.6))
            TextField("Search stories...", text: $vm.searchText).foregroundColor(.white)
            if !vm.searchText.isEmpty {
                Button("Clear") { vm.searchText = "" }.font(.caption).foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(10).background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12)).padding(.horizontal)
    }

    private var suggestedRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.suggested, id: \.self) { s in
                    Button(s) { vm.searchText = s.lowercased() }
                        .font(.caption.weight(.semibold)).foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.white.opacity(0.15), in: Capsule())
                }
            }.padding(.horizontal)
        }
    }

    private var storyList: some View {
        ScrollView {
            if vm.isLoading {
                ProgressView("Preparing your adventure...").tint(.white)
            } else if vm.filtered.isEmpty {
                VStack(spacing: 12) {
                    Text("🔍").font(.largeTitle)
                    Text("No stories found").font(.headline).foregroundColor(.white)
                    Text("Try another search").font(.caption).foregroundColor(.white.opacity(0.7))
                    Button("Try Again") { vm.searchText = ""; vm.selectedCategory = nil }.foregroundColor(AppColors.accent)
                }.padding(.top, 40)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(vm.filtered) { story in
                        StoryCardView(story: story).onTapGesture { selected = story; showDetail = true }
                    }
                }.padding(.horizontal)
            }
        }
    }
}
