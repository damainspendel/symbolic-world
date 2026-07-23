import SwiftUI
import SwiftData

@main
struct SpeculumApp: App {
    @StateObject private var graph = GraphStore()
    let container: ModelContainer

    init() {
        container = SpeculumApp.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            ReadingCompanionView()
                .environmentObject(graph)
                .tint(Palette.gold)
        }
        .modelContainer(container)
    }

    /// Study notes sync via CloudKit's private database (the user's own iCloud —
    /// never our servers). Falls back to a local-only store when CloudKit is
    /// unavailable (unsigned build / simulator / no iCloud account) so the app
    /// always runs.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([Note.self])
        do {
            let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            return try ModelContainer(for: schema, configurations: cloud)
        } catch {
            let local = ModelConfiguration(schema: schema)
            return try! ModelContainer(for: schema, configurations: local)
        }
    }
}

enum Palette {
    static let gold = Color(red: 0.61, green: 0.49, blue: 0.17)
    static let motif = Color(red: 0.49, green: 0.34, blue: 0.65)
    static let teal = Color(red: 0.18, green: 0.50, blue: 0.47)
}
