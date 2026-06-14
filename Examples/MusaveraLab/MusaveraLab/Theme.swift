import AppKit
import SwiftUI

enum LabTheme {
    static let background = Color(nsColor: .windowBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor).opacity(0.72)
    static let raisedSurface = Color(nsColor: .textBackgroundColor).opacity(0.58)
    static let separator = Color(nsColor: .separatorColor).opacity(0.34)
    static let accent = Color(nsColor: .systemPink)
    static let playhead = Color.primary.opacity(0.62)
    static let structure = accent
    static let segment = accent.opacity(0.72)
    static let phrase = accent.opacity(0.44)
    static let pace = accent
    static let loudness = accent

    static let contentWidth: CGFloat = 1_360
    static let sectionRadius: CGFloat = 14
}
