import AppKit
import SwiftUI

enum LabTheme {
    static let background = Color(nsColor: .windowBackgroundColor)
    static let card = Color(nsColor: .controlBackgroundColor)
    static let cardBorder = Color(nsColor: .separatorColor).opacity(0.45)
    static let playhead = Color.primary.opacity(0.62)
    static let structure = Color.blue
    static let segment = Color.teal
    static let phrase = Color.mint
    static let pace = Color.orange
    static let loudness = Color.indigo
}
