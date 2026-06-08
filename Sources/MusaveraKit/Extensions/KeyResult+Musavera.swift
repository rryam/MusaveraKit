import CoreMedia
import MusicUnderstanding

extension KeyResult {
    /// Returns the key signature whose time range contains the given time.
    public func signature(at time: CMTime) -> KeySignature? {
        ranges.first { rangedValue in
            rangedValue.range.containsTime(time)
        }?.value
    }

    /// The first detected key signature, useful for simple "song key" displays.
    public var primarySignature: KeySignature? {
        ranges.first?.value
    }
}

extension KeyResult.KeySignature {
    /// Human-readable key label, such as `C major` or `F# minor`.
    public var musaveraDescription: String {
        "\(tonic.musaveraDescription) \(mode.rawValue)"
    }
}

extension KeyResult.Tonic {
    public var musaveraDescription: String {
        switch self {
        case .aFlat:
            "Ab"
        case .aSharp:
            "A#"
        case .a:
            "A"
        case .bFlat:
            "Bb"
        case .b:
            "B"
        case .c:
            "C"
        case .cSharp:
            "C#"
        case .d:
            "D"
        case .dFlat:
            "Db"
        case .dSharp:
            "D#"
        case .eFlat:
            "Eb"
        case .e:
            "E"
        case .f:
            "F"
        case .fSharp:
            "F#"
        case .g:
            "G"
        case .gFlat:
            "Gb"
        case .gSharp:
            "G#"
        }
    }
}
