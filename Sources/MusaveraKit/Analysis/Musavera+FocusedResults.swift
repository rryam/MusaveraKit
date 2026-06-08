import AVFoundation
import Foundation
import MusicUnderstanding

extension Musavera {
    public static func rhythm(for asset: any AVAsset & Sendable) async throws -> RhythmResult {
        let analysis = try await analyze(asset: asset, options: .rhythm)
        guard let rhythm = analysis.rhythm else {
            throw MusaveraKitError.missingResult("rhythm")
        }
        return rhythm
    }

    public static func key(for asset: any AVAsset & Sendable) async throws -> KeyResult {
        let analysis = try await analyze(asset: asset, options: .key)
        guard let key = analysis.key else {
            throw MusaveraKitError.missingResult("key")
        }
        return key
    }

    public static func loudness(for asset: any AVAsset & Sendable) async throws -> LoudnessResult {
        let analysis = try await analyze(asset: asset, options: .loudness)
        guard let loudness = analysis.loudness else {
            throw MusaveraKitError.missingResult("loudness")
        }
        return loudness
    }

    public static func pace(for asset: any AVAsset & Sendable) async throws -> PaceResult {
        let analysis = try await analyze(asset: asset, options: .pace)
        guard let pace = analysis.pace else {
            throw MusaveraKitError.missingResult("pace")
        }
        return pace
    }

    public static func structure(for asset: any AVAsset & Sendable) async throws -> StructureResult {
        let analysis = try await analyze(asset: asset, options: .structure)
        guard let structure = analysis.structure else {
            throw MusaveraKitError.missingResult("structure")
        }
        return structure
    }

    public static func instrumentActivity(for asset: any AVAsset & Sendable) async throws -> InstrumentActivityResult {
        let analysis = try await analyze(asset: asset, options: .instrumentActivity)
        guard let instrumentActivity = analysis.instrumentActivity else {
            throw MusaveraKitError.missingResult("instrument activity")
        }
        return instrumentActivity
    }
}
