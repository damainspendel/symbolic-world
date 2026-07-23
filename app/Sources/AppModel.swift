import SwiftUI

/// Shared navigation state across the three tabs (Explore / Read / You).
@MainActor
final class AppModel: ObservableObject {
    @Published var volume: String
    @Published var paragraph: Int
    @Published var focusNodeID: String?     // node Explore should centre/highlight
    @Published var tab: Int = 0             // 0 Explore · 1 Read · 2 You
    @Published var trail: [Position] = []

    struct Position: Hashable { let volume: String; let paragraph: Int }

    init() {
        let d = UserDefaults.standard
        volume = d.string(forKey: "lastVolume") ?? "14"
        let p = d.integer(forKey: "lastParagraph")
        paragraph = (p == 0 ? 18 : p)
        trail = [Position(volume: volume, paragraph: paragraph)]
    }

    func go(volume v: String, paragraph p: Int) {
        volume = v; paragraph = p
        UserDefaults.standard.set(v, forKey: "lastVolume")
        UserDefaults.standard.set(p, forKey: "lastParagraph")
        let pos = Position(volume: v, paragraph: p)
        if trail.last != pos { trail.append(pos); trail = Array(trail.suffix(25)) }
    }

    /// Jump to a paragraph and open the Read tab.
    func read(volume v: String, paragraph p: Int) { go(volume: v, paragraph: p); tab = 1 }

    /// Highlight a node in the Explore tab.
    func showInGraph(_ nodeID: String) { focusNodeID = nodeID; tab = 0 }
}
