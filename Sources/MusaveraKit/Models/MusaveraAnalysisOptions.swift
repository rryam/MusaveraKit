import MusicUnderstanding

/// High-level analysis choices exposed by MusaveraKit.
public struct MusaveraAnalysisOptions: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let instrumentActivity = MusaveraAnalysisOptions(rawValue: 1 << 0)
    public static let key = MusaveraAnalysisOptions(rawValue: 1 << 1)
    public static let loudness = MusaveraAnalysisOptions(rawValue: 1 << 2)
    public static let pace = MusaveraAnalysisOptions(rawValue: 1 << 3)
    public static let rhythm = MusaveraAnalysisOptions(rawValue: 1 << 4)
    public static let structure = MusaveraAnalysisOptions(rawValue: 1 << 5)

    public static let all: MusaveraAnalysisOptions = [
        .instrumentActivity,
        .key,
        .loudness,
        .pace,
        .rhythm,
        .structure
    ]

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
