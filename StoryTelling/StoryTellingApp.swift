import SwiftUI
import Combine
import SwiftData

@main
struct StoryTellingApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([StoryProgress.self, AppUserProfile.self])

        // Ensure Application Support directory exists before SwiftData tries to create default.store
        // This silences the verbose CoreData "Failed to stat" recovery logs on Simulator
        let fm = FileManager.default
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? fm.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        // Explicit store URL in Application Support — more stable than default location
        let storeURL: URL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("WonderTales.store") ?? fm.temporaryDirectory.appendingPathComponent("WonderTales.store")

        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let ctx = container.mainContext
            let count = (try? ctx.fetchCount(FetchDescriptor<AppUserProfile>())) ?? 0
            if count == 0 {
                ctx.insert(AppUserProfile())
                try? ctx.save()
            }
            return container
        } catch {
            // Fallback to in-memory store so app still launches (prevents crash on permission edge cases)
            print("SwiftData failed with persistent store, falling back to in-memory: \(error)")
            let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                let container = try ModelContainer(for: schema, configurations: [memConfig])
                container.mainContext.insert(AppUserProfile())
                return container
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .modelContainer(sharedModelContainer)
        }
    }
}
