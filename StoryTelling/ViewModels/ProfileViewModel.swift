import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: AppUserProfile?
    @Published var showParentMode = false
    @Published var parentUnlocked = false

    private var storage: StorageService?
    func inject(_ s: StorageService) {
        storage = s
        profile = s.ensureProfile()
    }
    func updateName(_ name: String) { profile?.name = name }
    func updateAvatar(_ emoji: String) { profile?.avatarEmoji = emoji }
    func updateLanguage(_ lang: AppLanguage) { profile?.preferredLanguageRaw = lang.rawValue }
    var badges: [Badge] {
        guard let ids = profile?.badges else { return [] }
        return Badge.all.filter { ids.contains($0.id) }
    }
    func unlockParent(pin: String) -> Bool {
        // simple passcode 1234
        if pin == "1234" { parentUnlocked = true; return true }
        return false
    }
}
