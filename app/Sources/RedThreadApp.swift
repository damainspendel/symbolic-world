import SwiftUI
import SwiftData

@main
struct RedThreadApp: App {
    @StateObject private var graph = GraphStore()
    @StateObject private var app = AppModel()
    let container: ModelContainer

    init() {
        container = RedThreadApp.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(graph)
                .environmentObject(app)
                .tint(Palette.gold)
                .preferredColorScheme(.light)
        }
        .modelContainer(container)
    }

    /// Study notes/bookmarks sync via CloudKit's private database (the user's own
    /// iCloud). Falls back to local-only when CloudKit is unavailable so the app
    /// always runs.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([Note.self, Bookmark.self])
        do {
            let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            return try ModelContainer(for: schema, configurations: cloud)
        } catch {
            let local = ModelConfiguration(schema: schema)
            return try! ModelContainer(for: schema, configurations: local)
        }
    }
}

/// Explore is the home — the graph is the product. Read is the reading companion
/// you enter with a §. You holds the personal layer (trail, bookmarks, settings).
struct RootView: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        TabView(selection: $app.tab) {
            ExploreView()
                .tabItem { Label("Explore", systemImage: "point.3.filled.connected.trianglepath.dotted") }
                .tag(0)
            ReferenceView()
                .tabItem { Label("Read", systemImage: "book") }
                .tag(1)
            LibraryView()
                .tabItem { Label("You", systemImage: "bookmark") }
                .tag(2)
        }
    }
}

enum Palette {
    static let gold = Color(red: 0.61, green: 0.49, blue: 0.17)
    static let motif = Color(red: 0.49, green: 0.34, blue: 0.65)
    static let teal = Color(red: 0.18, green: 0.50, blue: 0.47)
}
