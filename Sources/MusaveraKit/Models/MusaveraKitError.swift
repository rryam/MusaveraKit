import Foundation

/// Errors surfaced by MusaveraKit convenience APIs.
public enum MusaveraKitError: Error, Equatable, Sendable {
    case emptyAnalysisSet
    case missingResult(String)
}

extension MusaveraKitError: CustomStringConvertible {
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
    public var errorDescription: String? {
        description
    }
}
