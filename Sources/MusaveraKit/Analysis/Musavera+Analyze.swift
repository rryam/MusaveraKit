import AVFoundation
import Foundation
import MusicUnderstanding

extension Musavera {
    /// Analyzes all supported musical dimensions for an asset.
    ///
    /// - Parameter asset: An audio asset that remains available until analysis
    ///   completes.
    /// - Returns: An aggregate containing every result produced by Music
    ///   Understanding.
    @discardableResult
    public static func analyze(asset: any AVAsset & Sendable) async throws -> MusaveraAnalysis {
        let session = try await MusicUnderstandingSession(asset: asset)
        return MusaveraAnalysis(result: try await session.analyze())
    }

    /// Analyzes selected musical dimensions for an asset.
    ///
    /// - Parameters:
    ///   - asset: An audio asset that remains available until analysis
    ///     completes.
    ///   - options: The analysis dimensions to request.
    /// - Returns: An aggregate containing the requested results.
    /// - Throws: ``MusaveraKitError/emptyAnalysisSet`` when `options` is empty,
    ///   or an error from Music Understanding.
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
