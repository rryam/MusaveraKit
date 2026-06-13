import CoreMedia
import Foundation
import MusicUnderstanding

/// A small, app-friendly wrapper around `MusicUnderstandingSession.SessionResult`.
public struct MusaveraAnalysis: Sendable {
    /// The original aggregate returned by Music Understanding.
    public let result: MusicUnderstandingSession.SessionResult

    /// Creates an app-friendly view of a Music Understanding session result.
    public init(result: MusicUnderstandingSession.SessionResult) {
        self.result = result
    }

    /// Activity ranges and values for detected instrument categories.
    public var instrumentActivity: InstrumentActivityResult? {
        result.instrumentActivity
    }

    /// Musical key signatures detected over the asset's timeline.
    public var key: KeyResult? {
        result.key
    }

    /// Integrated and time-varying loudness analysis.
    public var loudness: LoudnessResult? {
        result.loudness
    }

    /// Perceived pace values detected over the asset's timeline.
    public var pace: PaceResult? {
        result.pace
    }

    /// Tempo, beat, and bar analysis.
    public var rhythm: RhythmResult? {
        result.rhythm
    }

    /// Sections, phrases, and segments detected in the asset.
    public var structure: StructureResult? {
        result.structure
    }

    /// The detected tempo in beats per minute, when rhythm was requested.
    public var beatsPerMinute: Float? {
        rhythm?.beatsPerMinute
    }

    /// The number of detected beats, or zero when rhythm is unavailable.
    public var beatCount: Int {
        rhythm?.beats.count ?? 0
    }

    /// The number of detected bars, or zero when rhythm is unavailable.
    public var barCount: Int {
        rhythm?.bars.count ?? 0
    }

    /// The number of detected sections, or zero when structure is unavailable.
    public var sectionCount: Int {
        structure?.sections.count ?? 0
    }

    /// The number of detected phrases, or zero when structure is unavailable.
    public var phraseCount: Int {
        structure?.phrases.count ?? 0
    }

    /// The number of detected segments, or zero when structure is unavailable.
    public var segmentCount: Int {
        structure?.segments.count ?? 0
    }

    /// Returns the key signature active at a timeline position.
    public func keySignature(at time: CMTime) -> KeyResult.KeySignature? {
        key?.signature(at: time)
    }
}
