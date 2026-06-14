import AVFoundation
import Testing
@testable import MusaveraKit

@Suite("Musavera streaming session")
struct MusaveraStreamingSessionTests {
    @Test("Rejects an empty focused analysis set before consuming audio")
    func rejectsEmptyOptions() async {
        let buffers = AsyncStream<AVReadOnlyAudioPCMBuffer> { continuation in
            continuation.finish()
        }
        let session = MusaveraStreamingSession(audioProvider: buffers)

        await #expect(throws: MusaveraKitError.self) {
            _ = try await session.analyze(options: [])
        }
    }
}
