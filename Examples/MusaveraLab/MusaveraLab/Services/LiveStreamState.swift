import SwiftUI

enum LiveStreamState: Equatable {
    case idle
    case requestingPermission
    case listening
    case finalizing
    case complete

    var title: String {
        switch self {
        case .idle:
            "Ready"
        case .requestingPermission:
            "Requesting Access"
        case .listening:
            "Listening Live"
        case .finalizing:
            "Finishing Analysis"
        case .complete:
            "Analysis Complete"
        }
    }

    var systemImage: String {
        switch self {
        case .idle:
            "mic"
        case .requestingPermission:
            "lock.open"
        case .listening:
            "waveform.badge.microphone"
        case .finalizing:
            "waveform.path.ecg"
        case .complete:
            "checkmark.circle.fill"
        }
    }

    var tint: Color {
        LabTheme.accent
    }
}
