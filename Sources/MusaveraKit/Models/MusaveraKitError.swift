import Foundation

/// Errors surfaced by MusaveraKit convenience APIs.
public enum MusaveraKitError: Error, Equatable, Sendable {
    /// The caller requested no analysis types.
    case emptyAnalysisSet

    /// Music Understanding did not return a result requested by a focused API.
    case missingResult(String)
}

extension MusaveraKitError: CustomStringConvertible {
    /// A human-readable explanation of the package error.
    public var description: String {
        switch self {
        case .emptyAnalysisSet:
            "At least one analysis option is required."
        case .missingResult(let name):
            "MusicUnderstanding did not return a \(name) result."
        }
    }
}

extension MusaveraKitError: LocalizedError {
    /// The localized description presented through `LocalizedError`.
    public var errorDescription: String? {
        description
    }
}
