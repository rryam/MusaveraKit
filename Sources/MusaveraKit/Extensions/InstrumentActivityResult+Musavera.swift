import CoreMedia
import MusicUnderstanding

extension InstrumentActivityResult {
    public var vocalRanges: [CMTimeRange] {
        ranges[.vocal] ?? []
    }

    public var drumRanges: [CMTimeRange] {
        ranges[.drum] ?? []
    }

    public var bassRanges: [CMTimeRange] {
        ranges[.bass] ?? []
    }

    public var otherRanges: [CMTimeRange] {
        ranges[.other] ?? []
    }

    public func activity(for instrument: Instrument) -> [MusicUnderstandingSession.TimedValue<Float>] {
        activity[instrument] ?? []
    }
}
