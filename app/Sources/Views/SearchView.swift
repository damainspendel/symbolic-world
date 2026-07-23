import SwiftUI
import SwiftData

/// Search your own notes and bookmark labels — the recall half of "keep me
/// oriented." Results are §-anchored; one tap jumps the reading position.
struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var graph: GraphStore
    @Query private var notes: [Note]
    @Query private var bookmarks: [Bookmark]
    @Binding var volume: String
    @Binding var paragraph: Int
    @State private var query = ""

    private var matchedNotes: [Note] {
        query.isEmpty ? [] : notes.filter { $0.body.localizedCaseInsensitiveContains(query) }
    }
    private var matchedBookmarks: [Bookmark] {
        query.isEmpty ? [] : bookmarks.filter { $0.label.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Text("Search your notes and bookmarks by keyword — e.g. a symbol you remember jotting down.")
                        .foregroundStyle(.secondary)
                } else if matchedNotes.isEmpty && matchedBookmarks.isEmpty {
                    Text("No matches for “\(query)”.").foregroundStyle(.secondary)
                }

                if !matchedBookmarks.isEmpty {
                    Section("Bookmarks") {
                        ForEach(matchedBookmarks) { b in
                            Button { jump(b.volume, b.paragraph) } label: {
                                HStack {
                                    Image(systemName: "bookmark.fill").foregroundStyle(Palette.gold)
                                    Text(b.label)
                                    Spacer()
                                    citation(b.volume, b.paragraph)
                                }
                            }
                        }
                    }
                }
                if !matchedNotes.isEmpty {
                    Section("Notes") {
                        ForEach(matchedNotes) { n in
                            Button { jump(n.volume, n.paragraph) } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(n.body).lineLimit(2)
                                    citation(n.volume, n.paragraph)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search notes & bookmarks")
            .navigationTitle("Search")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func citation(_ v: String, _ p: Int) -> some View {
        Text("CW \(v) · §\(p)")
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
    }

    private func jump(_ v: String, _ p: Int) {
        volume = v; paragraph = p; dismiss()
    }
}
