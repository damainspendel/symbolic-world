import SwiftUI
#if os(macOS)
import AppKit
#endif

@MainActor
final class Camera: ObservableObject {
    @Published var scale: CGFloat = 1
    @Published var offset: CGSize = .zero
    var scaleBase: CGFloat = 1
    var offsetBase: CGSize = .zero
    func zoom(by f: CGFloat) {
        scale = min(max(scale * f, 0.2), 6)
        scaleBase = scale
    }
    func set(scale s: CGFloat, offset o: CGSize) {
        scale = min(max(s, 0.2), 6); scaleBase = scale
        offset = o; offsetBase = o
    }
}

/// The home tab. The graph fills the screen and is directly manipulable:
/// drag a node to reposition (and pin) it, drag empty space to pan, pinch or
/// scroll-wheel or the buttons to zoom, and "fit" to frame everything.
@MainActor
struct ExploreView: View {
    @EnvironmentObject private var graph: GraphStore
    @EnvironmentObject private var app: AppModel
    @StateObject private var engine = ForceLayout()
    @StateObject private var cam = Camera()
    @State private var selected: String?
    @State private var didSeed = false
    @State private var dragMode: DragMode = .idle
    #if os(macOS)
    @State private var scrollMonitor: Any?
    #endif

    enum DragMode: Equatable { case idle, node(Int), pan }

    private static let ground = Color(red: 0.949, green: 0.953, blue: 0.937)

    var body: some View {
        GeometryReader { geo in
            let layout = engine
            let selID = selected
            let sc = cam.scale
            let off = cam.offset
            ZStack {
                ExploreView.ground.ignoresSafeArea()

                TimelineView(.animation) { _ in
                    Canvas { ctx, size in
                        layout.step(size: size)
                        drawGraph(&ctx, layout: layout, selectedID: selID, scale: sc, offset: off)
                    }
                }
                .contentShape(Rectangle())
                .gesture(dragGesture)
                .simultaneousGesture(magnify)

                controls(geo.size)

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
                    Task {
                        try? await Task.sleep(nanoseconds: 1_200_000_000)
                        fit(geo.size)
                    }
                }
                installScrollMonitor()
            }
            .onDisappear { removeScrollMonitor() }
            .onChange(of: app.focusNodeID) { _, id in
                guard let id else { return }
                selected = id
                centre(on: id, size: geo.size)
                app.focusNodeID = nil
            }
        }
    }

    // MARK: geometry helpers

    private func graphPoint(_ p: CGPoint) -> CGPoint {
        CGPoint(x: (p.x - cam.offset.width) / cam.scale, y: (p.y - cam.offset.height) / cam.scale)
    }
    private func fit(_ size: CGSize) {
        guard let b = engine.bounds() else { return }
        let pad: CGFloat = 70
        let s = min((size.width - pad) / max(b.width, 1), (size.height - pad) / max(b.height, 1))
        let scale = min(max(s, 0.3), 2.5)
        cam.set(scale: scale,
                offset: CGSize(width: size.width / 2 - b.midX * scale,
                               height: size.height / 2 - b.midY * scale))
    }
    private func centre(on id: String, size: CGSize) {
        guard let n = engine.position(of: id) else { return }
        cam.offset = CGSize(width: size.width / 2 - n.x * cam.scale,
                            height: size.height / 2 - n.y * cam.scale)
        cam.offsetBase = cam.offset
        engine.reheat()
    }

    // MARK: gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { v in
                if dragMode == .idle {
                    if let i = engine.nodeIndex(at: graphPoint(v.startLocation)) {
                        dragMode = .node(i)
                    } else {
                        dragMode = .pan; cam.offsetBase = cam.offset
                    }
                }
                switch dragMode {
                case .node(let i):
                    engine.moveNode(i, to: graphPoint(v.location)); engine.reheat()
                case .pan:
                    cam.offset = CGSize(width: cam.offsetBase.width + v.translation.width,
                                        height: cam.offsetBase.height + v.translation.height)
                case .idle: break
                }
            }
            .onEnded { v in
                if dragMode == .idle, let i = engine.nodeIndex(at: graphPoint(v.location)) {
                    selected = engine.id(at: i); engine.reheat()   // a tap, not a drag
                }
                dragMode = .idle
            }
    }
    private var magnify: some Gesture {
        MagnifyGesture()
            .onChanged { v in cam.scale = min(max(cam.scaleBase * v.magnification, 0.2), 6) }
            .onEnded { _ in cam.scaleBase = cam.scale }
    }

    // MARK: scroll wheel (macOS)

    private func installScrollMonitor() {
        #if os(macOS)
        guard scrollMonitor == nil else { return }
        let camera = cam
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            let dy = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.deltaY * 3
            MainActor.assumeIsolated { camera.zoom(by: 1 + dy * 0.0022) }
            return nil
        }
        #endif
    }
    private func removeScrollMonitor() {
        #if os(macOS)
        if let m = scrollMonitor { NSEvent.removeMonitor(m); scrollMonitor = nil }
        #endif
    }

    // MARK: controls

    private func controls(_ size: CGSize) -> some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    ctlButton("plus.magnifyingglass") { cam.zoom(by: 1.25) }
                    ctlButton("minus.magnifyingglass") { cam.zoom(by: 0.8) }
                    ctlButton("arrow.up.left.and.arrow.down.right") { fit(size) }
                    ctlButton("arrow.counterclockwise") {
                        engine.unpinAll(); engine.reheat()
                        Task { try? await Task.sleep(nanoseconds: 900_000_000); fit(size) }
                    }
                }
                .padding()
            }
            Spacer()
        }
    }
    private func ctlButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.body).frame(width: 38, height: 38)
                .background(.regularMaterial, in: Circle()).foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: selected-node card

    private func nodeCard(_ node: GNode) -> some View {
        let touching = graph.edges(touching: node.id)
        let primary = touching.first?.primaryRef
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(node.type.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.gold)
                Spacer()
                if let r = primary {
                    Button {
                        app.read(volume: r.volume.raw, paragraph: r.paragraph)
                    } label: {
                        Label("Read §\(r.paragraph)", systemImage: "book")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.small)
                }
            }
            Text(node.label).font(.title3.weight(.semibold)).foregroundStyle(.primary)
            Divider().overlay(Color.primary.opacity(0.12))
            Text("\(touching.count) connection\(touching.count == 1 ? "" : "s") — tap to walk")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(touching) { e in
                let otherId = e.subject == node.id ? e.object : e.subject
                Button {
                    selected = otherId; engine.reheat()
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

// MARK: - drawing (nonisolated — Canvas renderer is @Sendable)

private func drawGraph(_ ctx: inout GraphicsContext, layout: ForceLayout, selectedID: String?,
                       scale: CGFloat, offset: CGSize) {
    ctx.translateBy(x: offset.width, y: offset.height)
    ctx.scaleBy(x: scale, y: scale)
    let selIdx = selectedID.flatMap { layout.index(of: $0) }
    for e in layout.edges {
        let a = layout.nodes[e.a], b = layout.nodes[e.b]
        let active = selIdx == e.a || selIdx == e.b
        var color = e.kind.color
        if selIdx != nil && !active { color = color.opacity(0.10) }
        var path = Path()
        path.move(to: CGPoint(x: a.x, y: a.y)); path.addLine(to: CGPoint(x: b.x, y: b.y))
        ctx.stroke(path, with: .color(color),
                   style: StrokeStyle(lineWidth: active ? 2.6 : (e.kind == .bridge ? 2.2 : 1.5),
                                      dash: e.kind == .amplification ? [4, 5] : []))
    }
    for (i, n) in layout.nodes.enumerated() {
        let active = selIdx == nil || selIdx == i || layout.isNeighbor(i, of: selIdx)
        let r: CGFloat = selIdx == i ? 13 : 10
        let rect = CGRect(x: n.x - r, y: n.y - r, width: r * 2, height: r * 2)
        ctx.fill(Circle().path(in: rect), with: .color(n.fill.opacity(active ? 1 : 0.22)))
        ctx.stroke(Circle().path(in: rect),
                   with: .color(n.ring.opacity(active ? 1 : 0.22)), lineWidth: n.pinned ? 3 : 1.6)
        let text = Text(n.label)
            .font(.system(size: 10, weight: selIdx == i ? .semibold : .regular))
            .foregroundColor(.black.opacity(active ? 0.85 : 0.28))
        ctx.draw(text, at: CGPoint(x: n.x, y: n.y + r + 8), anchor: .top)
    }
}

// MARK: - Force layout engine (Sendable value store, no view state)

final class ForceLayout: ObservableObject, @unchecked Sendable {
    struct LNode {
        let id: String, type: String, label: String
        let phase: String?
        var x: CGFloat, y: CGFloat, vx: CGFloat = 0, vy: CGFloat = 0
        var pinned = false
        var fill: Color { NodePalette.fill(type: type, phase: phase) }
        var ring: Color { NodePalette.ring(type: type) }
    }
    enum EdgeKind {
        case spine, amplification, bridge, structural
        var color: Color {
            switch self {
            case .spine: return Color(red: 0.62, green: 0.49, blue: 0.17)
            case .amplification: return Color(red: 0.49, green: 0.34, blue: 0.65)
            case .bridge: return Color(red: 0.18, green: 0.50, blue: 0.47)
            case .structural: return Color(white: 0.55)
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
    func id(at i: Int) -> String { nodes[i].id }
    func position(of id: String) -> CGPoint? { idIndex[id].map { CGPoint(x: nodes[$0].x, y: nodes[$0].y) } }
    func isNeighbor(_ i: Int, of j: Int?) -> Bool { guard let j else { return false }; return neighbors[j]?.contains(i) ?? false }
    func reheat() { alpha = max(alpha, 0.5) }

    func nodeIndex(at p: CGPoint) -> Int? {
        for i in 0..<nodes.count where hypot(nodes[i].x - p.x, nodes[i].y - p.y) < 16 { return i }
        return nil
    }
    func moveNode(_ i: Int, to p: CGPoint) {
        nodes[i].x = p.x; nodes[i].y = p.y; nodes[i].vx = 0; nodes[i].vy = 0; nodes[i].pinned = true
    }
    func unpinAll() { for i in nodes.indices { nodes[i].pinned = false } }
    func bounds() -> CGRect? {
        guard !nodes.isEmpty else { return nil }
        var minX = nodes[0].x, minY = nodes[0].y, maxX = nodes[0].x, maxY = nodes[0].y
        for n in nodes { minX = min(minX, n.x); minY = min(minY, n.y); maxX = max(maxX, n.x); maxY = max(maxY, n.y) }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    func seed(nodes gnodes: [GNode], edges gedges: [GEdge], size: CGSize) {
        guard !gnodes.isEmpty, size.width > 0 else { return }
        let cx = size.width / 2, cy = size.height / 2
        nodes = gnodes.enumerated().map { i, n in
            let ang = CGFloat(i) / CGFloat(gnodes.count) * .pi * 2
            return LNode(id: n.id, type: n.type, label: n.label, phase: n.colorPhase,
                         x: cx + cos(ang) * 120 + .random(in: -30...30),
                         y: cy + sin(ang) * 120 + .random(in: -30...30))
        }
        idIndex = Dictionary(uniqueKeysWithValues: nodes.enumerated().map { ($1.id, $0) })
        neighbors = [:]
        edges = gedges.compactMap { e in
            guard let a = idIndex[e.subject], let b = idIndex[e.object] else { return nil }
            let kind: EdgeKind = e.isBridge ? .bridge : e.isAmplification ? .amplification
                                : e.isStructural ? .structural : .spine
            neighbors[a, default: []].insert(b); neighbors[b, default: []].insert(a)
            return LEdge(a: a, b: b, kind: kind)
        }
        alpha = 1
    }

    func step(size: CGSize) {
        guard !nodes.isEmpty, size.width > 0, alpha > 0.02 else { return }
        let cx = size.width / 2, cy = size.height / 2
        let n = nodes.count
        var fx = [CGFloat](repeating: 0, count: n)
        var fy = [CGFloat](repeating: 0, count: n)
        for i in 0..<n {
            for j in (i + 1)..<n {
                var dx = nodes[i].x - nodes[j].x, dy = nodes[i].y - nodes[j].y
                var d2 = dx * dx + dy * dy
                if d2 < 0.01 { d2 = 0.01; dx = .random(in: -1...1) }
                let d = sqrt(d2)
                var f = 11000 / d2; if f > 12 { f = 12 }
                let ux = dx / d, uy = dy / d
                fx[i] += ux * f; fy[i] += uy * f; fx[j] -= ux * f; fy[j] -= uy * f
            }
        }
        for e in edges {
            let dx = nodes[e.b].x - nodes[e.a].x, dy = nodes[e.b].y - nodes[e.a].y
            let d = max(sqrt(dx * dx + dy * dy), 0.01)
            let f = (d - 180) * 0.035
            let ux = dx / d, uy = dy / d
            fx[e.a] += ux * f; fy[e.a] += uy * f; fx[e.b] -= ux * f; fy[e.b] -= uy * f
        }
        for i in 0..<n where !nodes[i].pinned {
            fx[i] += (cx - nodes[i].x) * 0.008
            fy[i] += (cy - nodes[i].y) * 0.008
            nodes[i].vx = (nodes[i].vx + fx[i]) * 0.84
            nodes[i].vy = (nodes[i].vy + fy[i]) * 0.84
            nodes[i].x += nodes[i].vx * alpha
            nodes[i].y += nodes[i].vy * alpha
        }
        alpha *= 0.992
    }
}

enum NodePalette {
    static func fill(type: String, phase: String?) -> Color {
        if let phase {
            switch phase {
            case "black": return Color(white: 0.12)
            case "white": return Color(red: 0.93, green: 0.91, blue: 0.84)
            case "red": return Color(red: 0.70, green: 0.23, blue: 0.18)
            default: break
            }
        }
        return ring(type: type)
    }
    static func ring(type: String) -> Color {
        switch type {
        case "Concept": return Color(red: 0.30, green: 0.52, blue: 0.62)
        case "Operation": return Color(red: 0.72, green: 0.47, blue: 0.28)
        case "Symbol": return Color(red: 0.72, green: 0.56, blue: 0.20)
        case "Figure": return Color(red: 0.72, green: 0.30, blue: 0.24)
        case "Substance": return Color(red: 0.38, green: 0.54, blue: 0.30)
        case "Motif": return Color(red: 0.49, green: 0.34, blue: 0.65)
        default: return .gray
        }
    }
}
