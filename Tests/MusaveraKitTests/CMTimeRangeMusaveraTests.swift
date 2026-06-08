import CoreMedia
import Testing
@testable import MusaveraKit

@Suite("CMTimeRange helpers")
struct CMTimeRangeMusaveraTests {
    @Test("Xcode 27 containsTime contains start and middle but excludes end")
    func containsTime() {
        let range = CMTimeRange(
            start: CMTime(seconds: 10, preferredTimescale: 600),
            duration: CMTime(seconds: 5, preferredTimescale: 600)
        )

        #expect(range.containsTime(CMTime(seconds: 10, preferredTimescale: 600)))
        #expect(range.containsTime(CMTime(seconds: 12, preferredTimescale: 600)))
        #expect(!range.containsTime(CMTime(seconds: 15, preferredTimescale: 600)))
    }
}
