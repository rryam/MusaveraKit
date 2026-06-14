import Foundation

enum LiveStreamError: LocalizedError {
    case microphonePermissionDenied
    case microphoneUnavailable
    case invalidInputFormat
    case noAudioCaptured
    case captureFailed(String)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            "Microphone access is off. Allow Musavera Lab in System Settings > Privacy & Security > Microphone."
        case .microphoneUnavailable:
            "No microphone input is available on this Mac."
        case .invalidInputFormat:
            "The selected microphone did not provide a usable PCM audio format."
        case .noAudioCaptured:
            "No microphone audio reached the analyzer. Check the selected input device and try again."
        case .captureFailed(let detail):
            "Live audio capture could not start: \(detail)"
        }
    }
}
