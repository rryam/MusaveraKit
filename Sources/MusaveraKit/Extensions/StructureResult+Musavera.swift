import CoreMedia
import MusicUnderstanding

extension StructureResult {
    /// Returns the song section containing the given time.
    public func section(containing time: CMTime) -> CMTimeRange? {
        sections.first { $0.containsTime(time) }
    }

    /// Returns the phrase containing the given time.
    public func phrase(containing time: CMTime) -> CMTimeRange? {
        phrases.first { $0.containsTime(time) }
    }

    /// Returns the segment containing the given time.
    public func segment(containing time: CMTime) -> CMTimeRange? {
        segments.first { $0.containsTime(time) }
    }
}
