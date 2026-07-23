import SwiftUI
import SwiftData

struct ReadingCompanionView: View {
    @EnvironmentObject private var graph: GraphStore
    @State private var volume = "14"
    @State private var paragraph = 18
    @State private var trail: [Position] = [Position(volume: "14", paragraph: 18)]
    @State private var selectedID: GEdge.ID?
    @State private var mode: Mode = .reference
    @State private var showSettings = false

    enum Mode: String, CaseIterable { case reference = "Reference", explore = "Explore" }
    struct Position: Hashable { let volume: String; let paragraph: Int }

    var body: some View {
        ZStack {
            if mode == .reference { referenceBody }
            else { ExploreView(volume: $volume, paragraph: $paragraph, selectedID: $selectedID) }
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 10) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
                Button { showSettings = true } label: { Image(systemName: "gearshape") }
                    .buttonStyle(.plain)
            }
            .padding(8)
            .background(.regularMaterial, in: Capsule())
            .padding(.bottom, 12)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private var nearby: [GEdge] {
        graph.edgesNear(volume: volume, paragraph: paragraph)
    }
    private var selectedEdge: GEdge? {
        nearby.first { $0.id == selectedID }
    }

    private var referenceBody: some View {
        NavigationSplitView {
            SidebarView(volume: $volume, paragraph: $paragraph, trail: trail)
                .navigationTitle("Red Thread")
        } content: {
            List(selection: $selectedID) {
                Section {
                    ForEach(nearby) { edge in
                        ClaimRow(edge: edge, here: edge.primaryRef?.paragraph == paragraph)
                            .tag(edge.id)
                    }
                } header: {
                    Text("Claims Jung anchors within ±25 § of §\(paragraph)")
                }
                if nearby.isEmpty {
                    Text("No grounded claims near here yet.")
                        .foregroundStyle(.secondary).italic()
                }
            }
            .navigationTitle("Around §\(paragraph)")
        } detail: {
            if let edge = selectedEdge {
                DetailView(edge: edge)
            } else {
                ContentUnavailableView("Select a claim",
                    systemImage: "sparkles",
                    description: Text("Pick a claim anchored near where you're reading."))
            }
        }
        .onChange(of: paragraph) { _, newValue in
            let pos = Position(volume: volume, paragraph: newValue)
            if trail.last != pos { trail.append(pos); trail = trail.suffix(6) }
        }
    }
}

// MARK: - Sidebar

private struct SidebarView: View {
    @EnvironmentObject private var graph: GraphStore
    @Binding var volume: String
    @Binding var paragraph: Int
    let trail: [ReadingCompanionView.Position]
    @Environment(\.modelContext) private var context
    @Query(sort: \Bookmark.created, order: .reverse) private var bookmarks: [Bookmark]

    var body: some View {
        List {
            Section("Your reading") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CW \(volume) · §\(paragraph)")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(Palette.gold)
                    Text("Mysterium Coniunctionis")
                        .font(.subheadline).italic().foregroundStyle(.secondary)
                    HStack {
                        Button { paragraph = max(1, paragraph - 1) } label: { Image(systemName: "chevron.left") }
                        Text("§\(paragraph)").font(.system(.body, design: .monospaced)).monospacedDigit()
                        Button { paragraph += 1 } label: { Image(systemName: "chevron.right") }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)
            }

            Section("Trail") {
                ForEach(Array(trail.enumerated()), id: \.offset) { _, pos in
                    HStack {
                        Circle().fill(pos == trail.last ? Palette.gold : Color.secondary.opacity(0.4))
                            .frame(width: 8, height: 8)
                        Text("CW \(pos.volume) · §\(pos.paragraph)")
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }

            Section("Bookmarks") {
                if bookmarks.isEmpty {
                    Text("No bookmarks yet").font(.caption).foregroundStyle(.secondary)
                }
                ForEach(bookmarks) { bm in
                    Button {
                        volume = bm.volume; paragraph = bm.paragraph
                    } label: {
                        HStack {
                            Image(systemName: "bookmark.fill").foregroundStyle(Palette.gold).font(.caption)
                            Text(bm.label)
                            Spacer()
                            Text("§\(bm.paragraph)").font(.system(.caption2, design: .monospaced)).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in offsets.map { bookmarks[$0] }.forEach(context.delete) }
            }
        }
    }
}

// MARK: - Claim row

private struct ClaimRow: View {
    @EnvironmentObject private var graph: GraphStore
    let edge: GEdge
    let here: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Text(graph.label(edge.subject)).fontWeight(.medium)
                Text(edge.relation).italic().foregroundStyle(Palette.gold)
                Text(graph.label(edge.object))
            }
            .font(.body)

            if let r = edge.primaryRef {
                Text("CW \(r.volume.display) · §\(r.paragraph)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text("“\(r.quote)”")
                    .font(.callout).italic().foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 6) {
                if here { Tag(text: "you are here", color: Palette.gold, filled: true) }
                if edge.isBridge { Tag(text: "bridge", color: Palette.teal) }
                else if edge.isAmplification { Tag(text: "amplification", color: Palette.motif) }
                if let c = edge.primaryRef?.confidence { Tag(text: c, color: .secondary) }
            }
        }
        .padding(.vertical, 3)
    }
}

private struct Tag: View {
    let text: String
    var color: Color
    var filled: Bool = false
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(filled ? color : color.opacity(0.14))
            .foregroundStyle(filled ? Color.white : color)
            .clipShape(Capsule())
    }
}

// MARK: - Detail + notes

private struct DetailView: View {
    @EnvironmentObject private var graph: GraphStore
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.created, order: .reverse) private var allNotes: [Note]
    let edge: GEdge
    @State private var draft = ""

    private var ref: GRef? { edge.primaryRef }
    private var notes: [Note] {
        guard let r = ref else { return [] }
        return allNotes.filter { $0.volume == r.volume.raw && $0.paragraph == r.paragraph }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(kindLabel).font(.system(.caption, design: .monospaced))
                    .foregroundStyle(edge.isAmplification ? Palette.motif : Palette.gold)

                (Text(graph.label(edge.subject)) + Text("  \(edge.relation)  ").italic().foregroundColor(Palette.gold) + Text(graph.label(edge.object)))
                    .font(.title2)

                if let r = ref {
                    Divider()
                    Text("CW \(r.volume.display) · §\(r.paragraph)")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(Palette.gold)
                    Text("“\(r.quote)”").font(.body).italic()

                    if let src = r.source {
                        Label("Jung quoting \(src)", systemImage: "text.book.closed")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    if let ct = r.claim_type {
                        Tag(text: ct, color: .secondary)
                    }

                    Button {
                        // Opens the user's own Collected Works at the cited page.
                    } label: {
                        Label(openLabel(r), systemImage: "book")
                    }
                    .buttonStyle(.borderedProminent)

                    Button { addBookmark(r) } label: {
                        Label("Bookmark this", systemImage: "bookmark")
                    }
                    .buttonStyle(.bordered)
                }

                Divider()
                notesSection
            }
            .padding(24)
            .frame(maxWidth: 560, alignment: .leading)
        }
        .navigationTitle("Claim")
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Study notes").font(.headline)
            ForEach(notes) { note in
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.body)
                    Text(note.created, style: .date)
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            HStack {
                TextField("Add a margin note…", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button("Add", action: addNote).disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Text("Synced via your iCloud (CloudKit) — never our servers.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func addNote() {
        guard let r = ref else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        context.insert(Note(body: text, volume: r.volume.raw, paragraph: r.paragraph))
        try? context.save()
        draft = ""
    }

    private func addBookmark(_ r: GRef) {
        context.insert(Bookmark(label: graph.label(edge.subject), volume: r.volume.raw, paragraph: r.paragraph))
        try? context.save()
    }

    private var kindLabel: String {
        if edge.isBridge { return "CROSS-VOLUME BRIDGE" }
        if edge.isAmplification { return "AMPLIFICATION · \((edge.kind ?? "").uppercased())" }
        return "INTERPRETIVE CLAIM"
    }

    private func openLabel(_ r: GRef) -> String {
        if let pg = graph.page(volume: r.volume.raw, paragraph: r.paragraph) {
            return "Open · Collected Works, Bollingen XX · vol. \(r.volume.display), p. \(pg)"
        }
        return "Open · Collected Works · vol. \(r.volume.display), §\(r.paragraph)"
    }
}
