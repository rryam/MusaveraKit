import AVFoundation
import Foundation
import MusicUnderstanding

extension Musavera {
    /// Analyze all supported musical dimensions for an asset.
    @discardableResult
    public static func analyze(asset: any AVAsset & Sendable) async throws -> MusaveraAnalysis {
        let session = try await MusicUnderstandingSession(asset: asset)
        return MusaveraAnalysis(result: try await session.analyze())
    }

    /// Analyze selected musical dimensions for an asset.
    @discardableResult
    public static func analyze(
        asset: any AVAsset & Sendable,
        options: MusaveraAnalysisOptions
    ) async throws -> MusaveraAnalysis {
        guard !options.isEmpty else {
            throw MusaveraKitError.emptyAnalysisSet
        }

        let session = try await MusicUnderstandingSession(asset: asset)
        let result = try await session.analyze(for: options.musicUnderstandingTypes)
        return MusaveraAnalysis(result: result)
    }
}
