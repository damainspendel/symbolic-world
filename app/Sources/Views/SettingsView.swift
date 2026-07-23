import SwiftUI
import SwiftData
import CloudKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.created, order: .reverse) private var notes: [Note]
    @Query(sort: \Bookmark.created, order: .reverse) private var bookmarks: [Bookmark]
    @State private var syncStatus = "Checking…"
    @State private var importing = false

    private struct Row: Codable { let body: String; let volume: String; let paragraph: Int }

    private var notesMarkdown: String {
        notes.isEmpty ? "No notes yet."
        : "# Red Thread — Study Notes\n\n" + notes.map(\.markdown).joined(separator: "\n")
    }
    private var notesJSON: String {
        let rows = notes.map { Row(body: $0.body, volume: $0.volume, paragraph: $0.paragraph) }
        let data = (try? JSONEncoder().encode(rows)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("iCloud sync") {
                    HStack {
                        Text("Status"); Spacer()
                        Text(syncStatus).foregroundStyle(.secondary)
                    }
                    Text("Notes and bookmarks sync through your private iCloud (CloudKit) — never our servers.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Notes") {
                    ShareLink("Export as Markdown", item: notesMarkdown)
                    ShareLink("Export as JSON (backup)", item: notesJSON)
                    Button("Import from JSON…") { importing = true }
                    Text("\(notes.count) note\(notes.count == 1 ? "" : "s")")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Bookmarks") {
                    if bookmarks.isEmpty {
                        Text("No bookmarks yet").foregroundStyle(.secondary)
                    }
                    ForEach(bookmarks) { bm in
                        HStack {
                            Image(systemName: "bookmark.fill").foregroundStyle(Palette.gold)
                            Text(bm.label)
                            Spacer()
                            Text("CW \(bm.volume) §\(bm.paragraph)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in offsets.map { bookmarks[$0] }.forEach(context.delete) }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .task { await refreshSyncStatus() }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                importNotes(result)
            }
        }
    }

    private func refreshSyncStatus() async {
        do {
            switch try await CKContainer.default().accountStatus() {
            case .available: syncStatus = "Signed in — syncing"
            case .noAccount: syncStatus = "No iCloud account (local only)"
            case .restricted: syncStatus = "Restricted"
            case .temporarilyUnavailable: syncStatus = "Temporarily unavailable"
            case .couldNotDetermine: syncStatus = "Unknown"
            @unknown default: syncStatus = "Unknown"
            }
        } catch {
            syncStatus = "Local only"
        }
    }

    private func importNotes(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([Row].self, from: data) else { return }
        for r in rows {
            context.insert(Note(body: r.body, volume: r.volume, paragraph: r.paragraph))
        }
        try? context.save()
    }
}
