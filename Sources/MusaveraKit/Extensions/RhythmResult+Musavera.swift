import CoreMedia
import MusicUnderstanding

extension RhythmResult {
    /// Returns the closest detected beat to a given time.
    public func nearestBeat(to time: CMTime) -> CMTime? {
        beats.min { lhs, rhs in
            abs(lhs.seconds - time.seconds) < abs(rhs.seconds - time.seconds)
        }
    }

    /// Returns the closest detected bar to a given time.
    public func nearestBar(to time: CMTime) -> CMTime? {
        bars.min { lhs, rhs in
            abs(lhs.seconds - time.seconds) < abs(rhs.seconds - time.seconds)
        }
    }
}
