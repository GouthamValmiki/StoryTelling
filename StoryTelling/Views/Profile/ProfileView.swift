import SwiftUI
import Combine
import SwiftData

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @State private var showAvatarPicker = false
    @State private var showParentSheet = false
    @State private var pin = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        profileHeader
                        stats
                        badgesSection
                        languagePicker
                        streakSection
                        parentMode
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { vm.inject(StorageService(context: context)) }
        .sheet(isPresented: $showAvatarPicker) {
            avatarPicker
        }
        .sheet(isPresented: $showParentSheet) { parentSheet }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Button(action: { showAvatarPicker = true }) {
                Text(vm.profile?.avatarEmoji ?? "👦").font(.system(size: 64)).padding(16).background(Color.white.opacity(0.15), in: Circle())
            }
            Text(vm.profile?.name ?? "Alex").font(.title2.weight(.bold)).foregroundColor(.white)
            Text("My Adventure").font(.caption).foregroundColor(.white.opacity(0.7))
            HStack(spacing: 6) {
                ForEach(Constants.avatars.prefix(5), id: \.self) { av in
                    Button(av) { vm.updateAvatar(av) }.font(.title3)
                }
            }
        }
        .padding(16).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var stats: some View {
        HStack(spacing: 12) {
            statCard(title: "Stories", value: "\(vm.profile?.totalStoriesCompleted ?? 0)", emoji: "📚")
            statCard(title: "Time", value: "\(vm.profile?.totalMinutes ?? 0) min", emoji: "⏱")
            statCard(title: "Genre", value: vm.profile?.favoriteGenreRaw ?? "Adventure", emoji: "❤️")
        }
    }
    private func statCard(title: String, value: String, emoji: String) -> some View {
        VStack(spacing: 6) { Text(emoji).font(.title2); Text(value).font(.headline).foregroundColor(.white); Text(title).font(.caption2).foregroundColor(.white.opacity(0.7)) }
            .frame(maxWidth: .infinity).padding(12).background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Badges").font(.headline).foregroundColor(.white)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Badge.all) { badge in
                        VStack(spacing: 6) {
                            Text(badge.emoji).font(.title)
                                .opacity(vm.badges.contains(badge) ? 1 : 0.25)
                            Text(badge.title).font(.caption2).foregroundColor(.white.opacity(0.8)).lineLimit(1)
                        }
                        .frame(width: 80).padding(10).background(Color.white.opacity(vm.badges.contains(badge) ? 0.12 : 0.06), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(14).background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose your story language").font(.headline).foregroundColor(.white)
            HStack(spacing: 12) {
                ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                    Button(action: { vm.updateLanguage(lang); appState.language = lang }) {
                        HStack { Text(lang.flag); Text(lang.displayName) }
                            .foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8)
                            .background {
                                if appState.language == lang {
                                    Capsule().fill(AppColors.gradientAccent)
                                } else {
                                    Capsule().fill(Color.white.opacity(0.12))
                                }
                            }
                    }
                }
            }
        }
        .padding(14).background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var streakSection: some View {
        HStack {
            Label("🔥 \(vm.profile?.streakDays ?? 0) Day Streak", systemImage: "flame.fill").foregroundColor(AppColors.accent)
            Spacer()
            Text("Keep exploring!").font(.caption).foregroundColor(.white.opacity(0.7))
        }.padding(14).background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var parentMode: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("Parent Mode").font(.headline).foregroundColor(.white); Spacer(); Button("Enter") { showParentSheet = true }.foregroundColor(AppColors.accent) }
            if vm.parentUnlocked {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Stories completed: \(vm.profile?.totalStoriesCompleted ?? 0)").foregroundColor(.white).font(.caption)
                    Text("Reading time: \(vm.profile?.totalMinutes ?? 0) min").foregroundColor(.white).font(.caption)
                    Text("Language: \(vm.profile?.preferredLanguageRaw ?? "en")").foregroundColor(.white).font(.caption)
                    Text("Age preference: \(vm.profile?.agePreference ?? "5-8")").foregroundColor(.white).font(.caption)
                }.padding(10).background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            } else {
                Text("Hidden & secured — enter PIN 1234 to view insights.").font(.caption).foregroundColor(.white.opacity(0.6))
            }
        }.padding(14).background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var avatarPicker: some View {
        NavigationStack {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                ForEach(Constants.avatars, id: \.self) { av in
                    Button(av) { vm.updateAvatar(av); showAvatarPicker = false }.font(.largeTitle).padding().background(Color.white.opacity(0.1), in: Circle())
                }
            }.padding().navigationTitle("Choose Avatar").navigationBarTitleDisplayMode(.inline)
        }
    }

    private var parentSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                SecureField("Enter PIN (1234)", text: $pin).textFieldStyle(.roundedBorder).padding()
                Button("Unlock") {
                    if vm.unlockParent(pin: pin) { showParentSheet = false }
                }.buttonStyle(.borderedProminent).tint(AppColors.primary)
                Spacer()
            }.navigationTitle("Parent Mode").navigationBarTitleDisplayMode(.inline)
        }
    }
}
