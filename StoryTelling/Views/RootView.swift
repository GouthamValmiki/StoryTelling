import SwiftUI
import Combine

final class AppState: ObservableObject {
    @AppStorage("appLanguage") var languageRaw: String = AppLanguage.english.rawValue
    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .english }
        set { languageRaw = newValue.rawValue; objectWillChange.send() }
    }
    @AppStorage("reduceMotion") var reduceMotion = false
}

struct RootView: View {
    @StateObject var appState = AppState()
    var body: some View {
        TabView {
            HomeView().tabItem { Label("Home", systemImage: "house.fill") }
            ExploreView().tabItem { Label("Explore", systemImage: "magnifyingglass") }
            FavoritesView().tabItem { Label("Favorites", systemImage: "heart.fill") }
            ProfileView().tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(AppColors.accent)
        .environmentObject(appState)
    }
}
