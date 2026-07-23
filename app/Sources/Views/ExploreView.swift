import SwiftUI

/// The dark "constellation" view of the whole graph — a force-directed layout
/// on a Canvas, walkable node-to-node. The Explore skin over the same data.
@MainActor
struct ExploreView: View {
    @EnvironmentObject private var graph: GraphStore
    @Binding var volume: String
    @Binding var paragraph: Int
    @Binding var selectedID: GEdge.ID?
    @State private var engine = ForceLayout()
    @State private var selected: String?
    @State private var didSeed = false
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private static let ground = Color(red: 0.949, green: 0.953, blue: 0.937)  // light vellum

    var body: some View {
        GeometryReader { geo in
            let layout = engine          // Sendable local, safe to capture in the render closure
            let selID = selected
            let sc = scale
            let off = offset
            ZStack {
                ExploreView.ground.ignoresSafeArea()

                TimelineView(.animation) { _ in
                    Canvas { ctx, size in
                        layout.step(size: size)
                        drawGraph(&ctx, layout: layout, selectedID: selID, scale: sc, offset: off)
                    }
                }
                .contentShape(Rectangle())
                .gesture(dragPan)
                .simultaneousGesture(magnify)
                .simultaneousGesture(tapSelect)

                controls

                if let id = selected, let node = graph.node(id) {
                    VStack { Spacer(); nodeCard(node) }
                        .padding(16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selected)
            .onAppear {
                if !didSeed {
                    engine.seed(nodes: graph.nodes, edges: graph.edges, size: geo.size)
                    didSeed = true
                }
            }
        }
    }

    // Convert a screen point back into graph space (undo pan + zoom).
    private func graphPoint(_ p: CGPoint) -> CGPoint {
        CGPoint(x: (p.x - offset.width) / scale, y: (p.y - offset.height) / scale)
    }

    private var tapSelect: some Gesture {
        SpatialTapGesture().onEnded { ev in
            if let id = engine.nodeID(at: graphPoint(ev.location)) {
                selected = id; engine.reheat(); focus(onNode: id)
            } else {
                selected = nil
            }
        }
    }
    private var dragPan: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { v in
                offset = CGSize(width: lastOffset.width + v.translation.width,
                                height: lastOffset.height + v.translation.height)
            }
            .onEnded { _ in lastOffset = offset }
    }
    private var magnify: some Gesture {
        MagnifyGesture()
            .onChanged { v in scale = min(max(lastScale * v.magnification, 0.4), 4.0) }
            .onEnded { _ in lastScale = scale }
    }
    private var controls: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    zoomButton("plus.magnifyingglass") { setScale(scale * 1.25) }
                    zoomButton("minus.magnifyingglass") { setScale(scale / 1.25) }
                    zoomButton("scope") {
                        withAnimation { scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero }
                        engine.reheat()
                    }
                }
                .padding()
            }
            Spacer()
        }
    }
    private func zoomButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.title3).frame(width: 40, height: 40)
                .background(.regularMaterial, in: Circle()).foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
    private func setScale(_ s: CGFloat) {
        withAnimation { scale = min(max(s, 0.4), 4.0) }
        lastScale = scale
    }

    /// Selecting in Explore preps Reference: point the reading position at the
    /// node's first grounded claim and select it, so a mode switch lands ready.
    private func focus(onNode id: String) {
        if let e = graph.edges(touching: id).first, let r = e.primaryRef {
            volume = r.volume.raw; paragraph = r.paragraph; selectedID = e.id
        }
    }

    // A walkable card for the tapped node — its grounded connections, tap to traverse.
    private func nodeCard(_ node: GNode) -> some View {
        let touching = graph.edges(touching: node.id)
        return VStack(alignment: .leading, spacing: 8) {
            Text(node.type.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.gold)
            Text(node.label).font(.title3.weight(.semibold)).foregroundStyle(.primary)
            Divider().overlay(Color.primary.opacity(0.12))
            Text("\(touching.count) connection\(touching.count == 1 ? "" : "s") — tap to walk")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(touching) { e in
                let otherId = e.subject == node.id ? e.object : e.subject
                Button {
                    selected = otherId; engine.reheat()
                    if let r = e.primaryRef { volume = r.volume.raw; paragraph = r.paragraph; selectedID = e.id }
                } label: {
                    HStack {
                        Text(e.subject == node.id
                             ? "\(e.relation) → \(graph.label(otherId))"
                             : "\(graph.label(otherId)) → \(e.relation)")
                            .font(.callout).foregroundStyle(.primary)
                        Spacer()
                        if let r = e.primaryRef {
                            Text("CW \(r.volume.display) §\(r.paragraph)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Palette.gold.opacity(0.8))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: 460, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.12)))
    }
}

/// Free (nonisolated) drawing function — the Canvas renderer closure is
/// @Sendable, so it can only touch Sendable values, not view state.
private func drawGraph(_ ctx: inout GraphicsContext, layout: ForceLayout, selectedID: String?, scale: CGFloat, offset: CGSize) {
    ctx.translateBy(x: offset.width, y: offset.height)
    ctx.scaleBy(x: scale, y: scale)
    let selIdx = selectedID.flatMap { layout.index(of: $0) }
    for e in layout.edges {
        let a = layout.nodes[e.a], b = layout.nodes[e.b]
        let active = selIdx == e.a || selIdx == e.b
        var color = e.kind.color
        if selIdx != nil && !active { color = color.opacity(0.12) }
        var path = Path()
        path.move(to: CGPoint(x: a.x, y: a.y))
        path.addLine(to: CGPoint(x: b.x, y: b.y))
        let style = StrokeStyle(lineWidth: active ? 2.4 : (e.kind == .bridge ? 2.0 : 1.3),
                                dash: e.kind == .amplification ? [3, 4] : [])
        ctx.stroke(path, with: .color(color), style: style)
    }
    for (i, n) in layout.nodes.enumerated() {
        let active = selIdx == nil || selIdx == i || layout.isNeighbor(i, of: selIdx)
        let r: CGFloat = selIdx == i ? 11 : 8
        let rect = CGRect(x: n.x - r, y: n.y - r, width: r * 2, height: r * 2)
        ctx.fill(Circle().path(in: rect), with: .color(n.fill.opacity(active ? 1 : 0.25)))
        ctx.stroke(Circle().path(in: rect), with: .color(n.ring.opacity(active ? 1 : 0.25)), lineWidth: 1.5)
        let text = Text(n.label)
            .font(.system(size: 9, weight: selIdx == i ? .semibold : .regular))
            .foregroundColor(.black.opacity(active ? 0.82 : 0.28))
        ctx.draw(text, at: CGPoint(x: n.x, y: n.y + r + 8), anchor: .top)
    }
}

// MARK: - Force-directed layout engine (Sendable value store, no view state)

final class ForceLayout: @unchecked Sendable {
    struct LNode {
        let id: String, type: String, label: String
        let phase: String?
        var x: CGFloat, y: CGFloat, vx: CGFloat = 0, vy: CGFloat = 0
        var fill: Color { NodePalette.fill(type: type, phase: phase) }
        var ring: Color { NodePalette.ring(type: type) }
    }
    enum EdgeKind {
        case spine, amplification, bridge, structural
        var color: Color {
            switch self {
            case .spine: return Color(red: 0.85, green: 0.70, blue: 0.37)
            case .amplification: return Color(red: 0.71, green: 0.54, blue: 0.82)
            case .bridge: return Color(red: 0.37, green: 0.78, blue: 0.74)
            case .structural: return Color(white: 0.4)
            }
        }
    }
    struct LEdge { let a: Int, b: Int; let kind: EdgeKind }

    private(set) var nodes: [LNode] = []
    private(set) var edges: [LEdge] = []
    private var idIndex: [String: Int] = [:]
    private var neighbors: [Int: Set<Int>] = [:]
    private var alpha: CGFloat = 1

    func index(of id: String) -> Int? { idIndex[id] }
    func nodeID(at p: CGPoint) -> String? {
        for i in 0..<nodes.count where hypot(nodes[i].x - p.x, nodes[i].y - p.y) < 18 { return nodes[i].id }
        return nil
    }
    func isNeighbor(_ i: Int, of j: Int?) -> Bool {
        guard let j else { return false }
        return neighbors[j]?.contains(i) ?? false
    }
    func reheat() { alpha = max(alpha, 0.5) }

    func seed(nodes gnodes: [GNode], edges gedges: [GEdge], size: CGSize) {
        guard !gnodes.isEmpty, size.width > 0 else { return }
        let cx = size.width / 2, cy = size.height / 2
        nodes = gnodes.enumerated().map { i, n in
            let ang = CGFloat(i) / CGFloat(gnodes.count) * .pi * 2
            return LNode(id: n.id, type: n.type, label: n.label, phase: n.colorPhase,
                         x: cx + cos(ang) * 70 + .random(in: -20...20),
                         y: cy + sin(ang) * 70 + .random(in: -20...20))
        }
        idIndex = Dictionary(uniqueKeysWithValues: nodes.enumerated().map { ($1.id, $0) })
        neighbors = [:]
        edges = gedges.compactMap { e in
            guard let a = idIndex[e.subject], let b = idIndex[e.object] else { return nil }
            let kind: EdgeKind = e.isBridge ? .bridge : e.isAmplification ? .amplification
                                : e.isStructural ? .structural : .spine
            neighbors[a, default: []].insert(b)
            neighbors[b, default: []].insert(a)
            return LEdge(a: a, b: b, kind: kind)
        }
        alpha = 1
    }

    func step(size: CGSize) {
        guard !nodes.isEmpty, size.width > 0 else { return }
        let cx = size.width / 2, cy = size.height / 2
        let count = nodes.count
        var fx = [CGFloat](repeating: 0, count: count)
        var fy = [CGFloat](repeating: 0, count: count)
        for i in 0..<count {
            for j in (i + 1)..<count {
                var dx = nodes[i].x - nodes[j].x, dy = nodes[i].y - nodes[j].y
                var d2 = dx * dx + dy * dy
                if d2 < 0.01 { d2 = 0.01; dx = .random(in: -1...1) }
                let d = sqrt(d2)
                var f = 6800 / d2; if f > 9 { f = 9 }
                let ux = dx / d, uy = dy / d
                fx[i] += ux * f; fy[i] += uy * f; fx[j] -= ux * f; fy[j] -= uy * f
            }
        }
        for e in edges {
            let dx = nodes[e.b].x - nodes[e.a].x, dy = nodes[e.b].y - nodes[e.a].y
            let d = max(sqrt(dx * dx + dy * dy), 0.01)
            let f = (d - 150) * 0.04
            let ux = dx / d, uy = dy / d
            fx[e.a] += ux * f; fy[e.a] += uy * f; fx[e.b] -= ux * f; fy[e.b] -= uy * f
        }
        let pad: CGFloat = 34
        for i in 0..<count {
            fx[i] += (cx - nodes[i].x) * 0.02
            fy[i] += (cy - nodes[i].y) * 0.02
            nodes[i].vx = (nodes[i].vx + fx[i]) * 0.82
            nodes[i].vy = (nodes[i].vy + fy[i]) * 0.82
            nodes[i].x += nodes[i].vx * alpha
            nodes[i].y += nodes[i].vy * alpha
            nodes[i].x = min(max(nodes[i].x, pad), size.width - pad)
            nodes[i].y = min(max(nodes[i].y, pad + 20), size.height - pad)
        }
        alpha *= 0.99
        if alpha < 0.03 { alpha = 0.03 }
    }
}

enum NodePalette {
    static func fill(type: String, phase: String?) -> Color {
        if let phase {
            switch phase {
            case "black": return Color(white: 0.10)
            case "white": return Color(red: 0.91, green: 0.89, blue: 0.82)
            case "red": return Color(red: 0.70, green: 0.23, blue: 0.18)
            default: break
            }
        }
        return ring(type: type)
    }
    static func ring(type: String) -> Color {
        switch type {
        case "Concept": return Color(red: 0.56, green: 0.72, blue: 0.79)
        case "Operation": return Color(red: 0.81, green: 0.60, blue: 0.42)
        case "Symbol": return Color(red: 0.85, green: 0.70, blue: 0.37)
        case "Figure": return Color(red: 0.82, green: 0.41, blue: 0.35)
        case "Substance": return Color(red: 0.53, green: 0.66, blue: 0.43)
        case "Motif": return Color(red: 0.71, green: 0.54, blue: 0.82)
        default: return .gray
        }
    }
}
