import SwiftUI
import SwiftData

/// The reading companion — entered with a §. A single column (no empty detail
/// pane): position controls + the claims Jung anchors nearby, each pushing a
/// full detail screen.
struct ReferenceView: View {
    @EnvironmentObject private var graph: GraphStore
    @EnvironmentObject private var app: AppModel
    @Environment(\.modelContext) private var context
    @State private var showSearch = false

    private var nearby: [GEdge] {
        graph.edgesNear(volume: app.volume, paragraph: app.paragraph)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CW \(app.volume) · §\(app.paragraph)")
                            .font(.system(.title3, design: .monospaced))
                            .foregroundStyle(Palette.gold)
                        Text("Mysterium Coniunctionis").font(.subheadline).italic().foregroundStyle(.secondary)
                        HStack {
                            Button { app.go(volume: app.volume, paragraph: max(1, app.paragraph - 1)) } label: { Image(systemName: "chevron.left") }
                            Text("§\(app.paragraph)").font(.system(.body, design: .monospaced)).monospacedDigit()
                            Button { app.go(volume: app.volume, paragraph: app.paragraph + 1) } label: { Image(systemName: "chevron.right") }
                            Spacer()
                            Button { bookmarkHere() } label: { Label("Bookmark", systemImage: "bookmark") }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }

                Section("Claims anchored within ±25 § of §\(app.paragraph)") {
                    if nearby.isEmpty {
                        Text("No grounded claims near here yet — try the Explore tab.")
                            .foregroundStyle(.secondary).italic()
                    }
                    ForEach(nearby) { edge in
                        NavigationLink(value: edge.id) {
                            ClaimRow(edge: edge, here: edge.primaryRef?.paragraph == app.paragraph)
                        }
                    }
                }
            }
            .navigationTitle("Read")
            .navigationDestination(for: String.self) { id in
                if let e = graph.edges.first(where: { $0.id == id }) { ClaimDetail(edge: e) }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showSearch = true } label: { Image(systemName: "magnifyingglass") }
                }
            }
            .sheet(isPresented: $showSearch) { SearchView() }
        }
    }

    private func bookmarkHere() {
        let label = nearby.first.map { graph.label($0.subject) } ?? "CW \(app.volume) §\(app.paragraph)"
        context.insert(Bookmark(label: label, volume: app.volume, paragraph: app.paragraph))
        try? context.save()
    }
}

// MARK: - Claim row + detail (shared)

struct ClaimRow: View {
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
                    .font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                Text("“\(r.quote)”").font(.callout).italic().foregroundStyle(.secondary).lineLimit(2)
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

struct Tag: View {
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

struct ClaimDetail: View {
    @EnvironmentObject private var graph: GraphStore
    @EnvironmentObject private var app: AppModel
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
                        .font(.system(.subheadline, design: .monospaced)).foregroundStyle(Palette.gold)
                    Text("“\(r.quote)”").font(.body).italic()
                    if let src = r.source {
                        Label("Jung quoting \(src)", systemImage: "text.book.closed").font(.callout).foregroundStyle(.secondary)
                    }
                    if let ct = r.claim_type { Tag(text: ct, color: .secondary) }

                    HStack {
                        Button { } label: { Label(openLabel(r), systemImage: "book") }
                            .buttonStyle(.borderedProminent)
                        Button { app.showInGraph(edge.subject) } label: { Label("Show in graph", systemImage: "point.3.connected.trianglepath.dotted") }
                            .buttonStyle(.bordered)
                    }
                }

                Divider()
                notesSection
            }
            .padding(20)
            .frame(maxWidth: 620, alignment: .leading)
        }
        .navigationTitle("Claim")
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Study notes").font(.headline)
            ForEach(notes) { note in
                Text(note.body)
                    .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 8))
            }
            HStack {
                TextField("Add a margin note…", text: $draft, axis: .vertical).textFieldStyle(.roundedBorder)
                Button("Add", action: addNote).disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Text("Synced via your iCloud (CloudKit).").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func addNote() {
        guard let r = ref else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        context.insert(Note(body: text, volume: r.volume.raw, paragraph: r.paragraph))
        try? context.save(); draft = ""
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
        return "Open · vol. \(r.volume.display), §\(r.paragraph)"
    }
}
