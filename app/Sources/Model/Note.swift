import Foundation
import SwiftData

/// A study/margin note anchored to a Collected Works paragraph.
/// All properties are defaulted (a CloudKit requirement) so the record syncs
/// through the user's private iCloud database.
@Model
final class Note {
    var id: UUID = UUID()
    var body: String = ""
    var volume: String = ""
    var paragraph: Int = 0
    var created: Date = Date()
    var modified: Date = Date()

    init(body: String, volume: String, paragraph: Int) {
        self.body = body
        self.volume = volume
        self.paragraph = paragraph
    }

    /// Markdown export — note text with its citation, per the confirmed format.
    var markdown: String {
        "- \(body)  \n  — *Collected Works, vol. \(volume), §\(paragraph)*"
    }
}

/// A bookmarked node/claim, anchored to a paragraph. Syncs via CloudKit too.
@Model
final class Bookmark {
    var id: UUID = UUID()
    var label: String = ""
    var volume: String = ""
    var paragraph: Int = 0
    var created: Date = Date()

    init(label: String, volume: String, paragraph: Int) {
        self.label = label
        self.volume = volume
        self.paragraph = paragraph
    }
}
