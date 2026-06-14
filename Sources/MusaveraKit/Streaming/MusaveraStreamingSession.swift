@preconcurrency import AVFoundation
import MusicUnderstanding

/// A MusaveraKit session that analyzes an asynchronous stream of PCM buffers.
///
/// Use ``loudnessResults`` for measurements that arrive while audio is
/// streaming. The complete ``MusaveraAnalysis`` becomes available after the
/// audio provider finishes.
public struct MusaveraStreamingSession: Sendable {
    private let session: MusicUnderstandingSession

    /// Creates a streaming analysis session.
    ///
    /// - Parameter audioProvider: A nonthrowing asynchronous sequence of
    ///   read-only PCM buffers.
    public init<Provider>(audioProvider: sending Provider)
    where Provider: AsyncSequence & Sendable,
          Provider.Element == AVReadOnlyAudioPCMBuffer,
          Provider.Failure == Never {
        session = MusicUnderstandingSession(audioProvider: audioProvider)
    }

    /// Loudness measurements that arrive while the provider yields audio.
    public var loudnessResults: some Sendable & AsyncSequence<LoudnessResult, any Error> {
        session.loudnessResults
    }

    /// Analyzes every supported musical dimension in the streamed audio.
    ///
    /// This method returns after the audio provider finishes and Music
    /// Understanding completes its final analysis.
    @discardableResult
    public func analyze() async throws -> MusaveraAnalysis {
        MusaveraAnalysis(result: try await session.analyze())
    }

    /// Analyzes selected musical dimensions in the streamed audio.
    ///
    /// - Parameter options: The musical dimensions to request.
    /// - Throws: ``MusaveraKitError/emptyAnalysisSet`` when `options` is empty,
    ///   or an error from Music Understanding.
    @discardableResult
    public func analyze(options: MusaveraAnalysisOptions) async throws -> MusaveraAnalysis {
        guard !options.isEmpty else {
            throw MusaveraKitError.emptyAnalysisSet
        }

        let result = try await session.analyze(for: options.musicUnderstandingTypes)
        return MusaveraAnalysis(result: result)
    }

    /// Cancels ongoing streaming analysis.
    public func cancel() async {
        await session.cancel()
    }
}
