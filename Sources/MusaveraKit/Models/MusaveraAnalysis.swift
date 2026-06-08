import CoreMedia
import Foundation
import MusicUnderstanding

/// A small, app-friendly wrapper around `MusicUnderstandingSession.SessionResult`.
public struct MusaveraAnalysis: Sendable {
    public let result: MusicUnderstandingSession.SessionResult

    public init(result: MusicUnderstandingSession.SessionResult) {
        self.result = result
    }

    public var instrumentActivity: InstrumentActivityResult? {
        result.instrumentActivity
    }

    public var key: KeyResult? {
        result.key
    }

    public var loudness: LoudnessResult? {
        result.loudness
    }

    public var pace: PaceResult? {
        result.pace
    }

    public var rhythm: RhythmResult? {
        result.rhythm
    }

    public var structure: StructureResult? {
        result.structure
    }

    public var beatsPerMinute: Float? {
        rhythm?.beatsPerMinute
    }

    public var beatCount: Int {
        rhythm?.beats.count ?? 0
    }

    public var barCount: Int {
        rhythm?.bars.count ?? 0
    }

    public var sectionCount: Int {
        structure?.sections.count ?? 0
    }

    public var phraseCount: Int {
        structure?.phrases.count ?? 0
    }

    public var segmentCount: Int {
        structure?.segments.count ?? 0
    }

    public func keySignature(at time: CMTime) -> KeyResult.KeySignature? {
        key?.signature(at: time)
    }
}
