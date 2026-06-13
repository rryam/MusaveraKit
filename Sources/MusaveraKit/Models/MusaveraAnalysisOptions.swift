import MusicUnderstanding

/// High-level analysis choices exposed by MusaveraKit.
public struct MusaveraAnalysisOptions: OptionSet, Sendable {
    /// The raw bit set used to represent selected analysis types.
    public let rawValue: Int

    /// Creates an analysis option set from a raw bit set.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Detects activity for vocal, drum, bass, and other instruments.
    public static let instrumentActivity = MusaveraAnalysisOptions(rawValue: 1 << 0)

    /// Detects musical key signatures over time.
    public static let key = MusaveraAnalysisOptions(rawValue: 1 << 1)

    /// Measures integrated and time-varying loudness.
    public static let loudness = MusaveraAnalysisOptions(rawValue: 1 << 2)

    /// Measures changes in perceived pace.
    public static let pace = MusaveraAnalysisOptions(rawValue: 1 << 3)

    /// Detects tempo, beats, and bars.
    public static let rhythm = MusaveraAnalysisOptions(rawValue: 1 << 4)

    /// Detects sections, phrases, and segments.
    public static let structure = MusaveraAnalysisOptions(rawValue: 1 << 5)

    /// Requests every analysis type supported by MusaveraKit.
    public static let all: MusaveraAnalysisOptions = [
        .instrumentActivity,
        .key,
        .loudness,
        .pace,
        .rhythm,
        .structure
    ]

    /// The Music Understanding analysis types represented by this option set.
    public var musicUnderstandingTypes: Set<AnalysisType> {
        var types = Set<AnalysisType>()

        if contains(.instrumentActivity) {
            types.insert(.instrumentActivity)
        }
        if contains(.key) {
            types.insert(.key)
        }
        if contains(.loudness) {
            types.insert(.loudness)
        }
        if contains(.pace) {
            types.insert(.pace)
        }
        if contains(.rhythm) {
            types.insert(.rhythm)
        }
        if contains(.structure) {
            types.insert(.structure)
        }

        return types
    }
}
