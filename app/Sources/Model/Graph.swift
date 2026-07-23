import Foundation

/// Volume codes are mixed in the graph JSON: integers (12, 13, 14) for the
/// alchemy volumes and strings ("9ii") for Aion. Decode either into a String.
struct VolCode: Codable, Hashable {
    let raw: String
    init(_ s: String) { raw = s }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { raw = s }
        else if let i = try? c.decode(Int.self) { raw = String(i) }
        else { raw = "?" }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer(); try c.encode(raw)
    }
    /// How the volume prints in a citation, e.g. "14" or "9ii".
    var display: String { raw }
}

struct GNode: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let label: String
    var tradition: String?
    var colorPhase: String?

    enum CodingKeys: String, CodingKey {
        case id, type, label, tradition
        case colorPhase = "color_phase"
    }
}

struct GRef: Codable, Hashable {
    let volume: VolCode
    let paragraph: Int
    let quote: String
    let confidence: String
    var claim_type: String?
    var source: String?
}

struct GEdge: Codable, Identifiable, Hashable {
    var id: String { "\(subject)|\(relation)|\(object)" }
    let subject: String
    let relation: String
    let object: String
    var layer: String?
    var kind: String?
    var bridge: Bool?
    var references: [GRef]

    var isAmplification: Bool { layer == "amplification" }
    var isBridge: Bool { bridge == true }
    var isStructural: Bool { references.isEmpty }
    var primaryRef: GRef? { references.first }
}

@MainActor
final class GraphStore: ObservableObject {
    @Published private(set) var nodes: [GNode] = []
    @Published private(set) var edges: [GEdge] = []
    private var pages: [String: Int] = [:]
    private var byId: [String: GNode] = [:]

    init() { load() }

    func node(_ id: String) -> GNode? { byId[id] }
    func label(_ id: String) -> String { byId[id]?.label ?? id }
    func page(volume: String, paragraph: Int) -> Int? { pages["\(volume):\(paragraph)"] }

    /// Every claim Jung anchors within ±window paragraphs of a reading position.
    func edgesNear(volume: String, paragraph: Int, window: Int = 25) -> [GEdge] {
        edges.filter { e in
            e.references.contains {
                $0.volume.raw == volume && abs($0.paragraph - paragraph) <= window
            }
        }
        .sorted { ($0.primaryRef?.paragraph ?? 0) < ($1.primaryRef?.paragraph ?? 0) }
    }

    func edges(touching id: String) -> [GEdge] {
        edges.filter { $0.subject == id || $0.object == id }
    }

    private struct Graph: Codable { let nodes: [GNode]; let edges: [GEdge] }

    private func load() {
        if let url = Bundle.main.url(forResource: "graph", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let g = try? JSONDecoder().decode(Graph.self, from: data) {
            nodes = g.nodes
            edges = g.edges
            byId = Dictionary(g.nodes.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        }
        if let url = Bundle.main.url(forResource: "pages", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let p = try? JSONDecoder().decode([String: Int].self, from: data) {
            pages = p
        }
    }
}
