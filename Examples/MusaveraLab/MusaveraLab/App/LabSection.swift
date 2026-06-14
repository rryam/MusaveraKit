import SwiftUI

enum LabSection: String, CaseIterable, Identifiable {
    case analyze
    case live

    var id: Self { self }

    var title: String {
        switch self {
        case .analyze:
            "Analyze Music"
        case .live:
            "Live Stream"
        }
    }

    var subtitle: String {
        switch self {
        case .analyze:
            "Apple Music previews and audio files"
        case .live:
            "Microphone loudness and final analysis"
        }
    }

    var systemImage: String {
        switch self {
        case .analyze:
            "waveform.path.ecg"
        case .live:
            "waveform.badge.microphone"
        }
    }
}
