import CoreMedia
import MusicUnderstanding

extension InstrumentActivityResult {
    /// Time ranges where Music Understanding detects vocals.
    public var vocalRanges: [CMTimeRange] {
        ranges[.vocal] ?? []
    }

    /// Time ranges where Music Understanding detects drums.
    public var drumRanges: [CMTimeRange] {
        ranges[.drum] ?? []
    }

    /// Time ranges where Music Understanding detects bass.
    public var bassRanges: [CMTimeRange] {
        ranges[.bass] ?? []
    }

    /// Time ranges where Music Understanding detects other instruments.
    public var otherRanges: [CMTimeRange] {
        ranges[.other] ?? []
    }

    /// Returns the time-varying activity values for an instrument category.
    public func activity(for instrument: Instrument) -> [MusicUnderstandingSession.TimedValue<Float>] {
        activity[instrument] ?? []
    }
}
