import SwiftUI
import SwiftData

/// "You" — the personal layer: resume, reading history (trail), bookmarks,
/// search, and settings.
struct LibraryView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Bookmark.volume), SortDescriptor(\Bookmark.paragraph)]) private var bookmarks: [Bookmark]
    @State private var showSearch = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { app.tab = 1 } label: {
                        Label("Resume at CW \(app.volume) · §\(app.paragraph)", systemImage: "book.fill")
                    }
                    Button { showSearch = true } label: {
                        Label("Search notes & bookmarks", systemImage: "magnifyingglass")
                    }
                }
                .buttonStyle(.plain)

                Section("Trail") {
                    if app.trail.count <= 1 {
                        Text("Your reading history will appear here.").foregroundStyle(.secondary)
                    }
                    ForEach(Array(app.trail.reversed().enumerated()), id: \.offset) { _, pos in
                        Button { app.read(volume: pos.volume, paragraph: pos.paragraph) } label: {
                            HStack {
                                Circle().fill(Palette.gold.opacity(0.5)).frame(width: 8, height: 8)
                                Text("CW \(pos.volume) · §\(pos.paragraph)").font(.system(.body, design: .monospaced))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Bookmarks") {
                    if bookmarks.isEmpty {
                        Text("No bookmarks yet — add one from Read or the graph.").foregroundStyle(.secondary)
                    }
                    ForEach(bookmarks) { bm in
                        Button { app.read(volume: bm.volume, paragraph: bm.paragraph) } label: {
                            HStack {
                                Image(systemName: "bookmark.fill").foregroundStyle(Palette.gold)
                                Text(bm.label)
                                Spacer()
                                Text("CW \(bm.volume) §\(bm.paragraph)")
                                    .font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in offsets.map { bookmarks[$0] }.forEach(context.delete) }
                }

                Section {
                    NavigationLink { SettingsView() } label: { Label("Settings", systemImage: "gearshape") }
                }
            }
            .navigationTitle("You")
            .sheet(isPresented: $showSearch) { SearchView() }
        }
    }
}
