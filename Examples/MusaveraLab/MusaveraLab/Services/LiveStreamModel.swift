@preconcurrency import AVFoundation
import Foundation
import MusicUnderstanding
import MusaveraKit
import Observation

@Observable
@MainActor
final class LiveStreamModel {
    typealias TimedFloat = MusicUnderstandingSession.TimedValue<Float>

    private(set) var state: LiveStreamState = .idle
    private(set) var sampleRate: Double = 0
    private(set) var channelCount = 0
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var bufferCount = 0
    private(set) var latestLoudness: LoudnessResult?
    private(set) var momentaryHistory: [TimedFloat] = []
    private(set) var finalAnalysis: MusaveraAnalysis?
    var errorMessage: String?

    @ObservationIgnored private var audioEngine: AVAudioEngine?
    @ObservationIgnored private var continuation: AsyncStream<AVReadOnlyAudioPCMBuffer>.Continuation?
    @ObservationIgnored private var streamingSession: MusaveraStreamingSession?
    @ObservationIgnored private var analysisTask: Task<Void, Never>?
    @ObservationIgnored private var loudnessTask: Task<Void, Never>?
    @ObservationIgnored private var tapInstalled = false
    @ObservationIgnored private var capturedFrameCount: Int64 = 0

    isolated deinit {
        analysisTask?.cancel()
        loudnessTask?.cancel()
        continuation?.finish()

        if tapInstalled {
            audioEngine?.inputNode.removeTap(onBus: 0)
        }
        audioEngine?.stop()

        if let streamingSession {
            Task {
                await streamingSession.cancel()
            }
        }
    }

    var isListening: Bool {
        state == .listening
    }

    var isWorking: Bool {
        state == .requestingPermission || state == .finalizing
    }

    var canReset: Bool {
        state != .idle
            || finalAnalysis != nil
            || latestLoudness != nil
            || errorMessage != nil
    }

    var latestMomentaryValue: Float? {
        latestLoudness?.momentary.last?.value
    }

    var latestShortTermValue: Float? {
        latestLoudness?.shortTerm.last?.value
    }

    var integratedValue: Float? {
        latestLoudness?.integrated.value
    }

    var peakValue: Float? {
        latestLoudness?.peak.value
    }

    var microphonePermissionDenied: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return status == .denied || status == .restricted
    }

    func start() async {
        guard state == .idle || state == .complete else { return }

        prepareForNewCapture()
        state = .requestingPermission

        guard await requestMicrophoneAccess() else {
            fail(with: LiveStreamError.microphonePermissionDenied)
            return
        }

        do {
            try beginCapture()
        } catch {
            fail(with: error)
        }
    }

    func stop() {
        guard state == .listening else { return }

        finishAudioProvider()

        guard capturedFrameCount > 0 else {
            fail(with: LiveStreamError.noAudioCaptured)
            return
        }

        state = .finalizing
    }

    func finishIfNeeded() {
        if state == .listening {
            stop()
        }
    }

    func reset() {
        cancelActiveSession()
        clearResults()
        state = .idle
        errorMessage = nil
    }

    private func requestMicrophoneAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            true
        case .notDetermined:
            await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            false
        @unknown default:
            false
        }
    }

    private func beginCapture() throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw LiveStreamError.invalidInputFormat
        }

        let pair = AsyncStream<AVReadOnlyAudioPCMBuffer>.makeStream(
            bufferingPolicy: .unbounded
        )
        let session = MusaveraStreamingSession(audioProvider: pair.stream)

        audioEngine = engine
        continuation = pair.continuation
        streamingSession = session
        sampleRate = format.sampleRate
        channelCount = Int(format.channelCount)

        observeLoudness(from: session)
        analyzeStream(with: session)

        let preferredFrameCount = Int(format.sampleRate * 0.12)
        let bufferSize = AVAudioFrameCount(max(preferredFrameCount, 512))

        do {
            try inputNode.installAudioTap(
                onBus: 0,
                bufferSize: bufferSize,
                format: format
            ) { [weak self, continuation = pair.continuation] buffer, _ in
                continuation.yield(buffer)
                let frameLength = buffer.frameLength

                Task { @MainActor [weak self] in
                    self?.recordCapturedFrames(frameLength)
                }
            }
            tapInstalled = true

            engine.prepare()
            try engine.start()
            state = .listening
        } catch {
            finishAudioProvider()
            throw LiveStreamError.captureFailed(error.localizedDescription)
        }
    }

    private func observeLoudness(from session: MusaveraStreamingSession) {
        loudnessTask = Task { [weak self] in
            do {
                for try await result in session.loudnessResults {
                    guard !Task.isCancelled else { return }
                    self?.receive(loudness: result)
                }
            } catch {
                guard !Task.isCancelled else { return }
                self?.fail(with: error)
            }
        }
    }

    private func analyzeStream(with session: MusaveraStreamingSession) {
        analysisTask = Task { [weak self] in
            do {
                let analysis = try await session.analyze()
                guard !Task.isCancelled else { return }
                self?.complete(with: analysis)
            } catch {
                guard !Task.isCancelled else { return }
                self?.fail(with: error)
            }
        }
    }

    private func recordCapturedFrames(_ frameCount: Int) {
        guard state == .listening else { return }

        capturedFrameCount += Int64(frameCount)
        bufferCount += 1
        elapsedTime = Double(capturedFrameCount) / sampleRate
    }

    private func receive(loudness: LoudnessResult) {
        guard state == .listening || state == .finalizing else { return }

        latestLoudness = loudness

        let lastTime = momentaryHistory.last?.time.seconds ?? -.greatestFiniteMagnitude
        momentaryHistory.append(
            contentsOf: loudness.momentary.filter { $0.time.seconds > lastTime }
        )

        if momentaryHistory.count > 1_500 {
            momentaryHistory.removeFirst(momentaryHistory.count - 1_500)
        }
    }

    private func complete(with analysis: MusaveraAnalysis) {
        guard state == .listening || state == .finalizing else { return }

        if state == .listening {
            finishAudioProvider()
        }

        finalAnalysis = analysis
        if let finalLoudness = analysis.loudness {
            receive(loudness: finalLoudness)
        }
        state = .complete
        streamingSession = nil
        analysisTask = nil
        loudnessTask = nil
    }

    private func prepareForNewCapture() {
        cancelActiveSession()
        clearResults()
        errorMessage = nil
        state = .idle
    }

    private func clearResults() {
        sampleRate = 0
        channelCount = 0
        elapsedTime = 0
        bufferCount = 0
        capturedFrameCount = 0
        latestLoudness = nil
        momentaryHistory = []
        finalAnalysis = nil
    }

    private func finishAudioProvider() {
        audioEngine?.stop()

        if tapInstalled {
            audioEngine?.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }

        continuation?.finish()
        continuation = nil
        audioEngine = nil
    }

    private func cancelActiveSession() {
        let session = streamingSession

        analysisTask?.cancel()
        loudnessTask?.cancel()
        analysisTask = nil
        loudnessTask = nil
        finishAudioProvider()
        streamingSession = nil

        if let session {
            Task {
                await session.cancel()
            }
        }
    }

    private func fail(with error: any Error) {
        cancelActiveSession()
        state = .idle
        errorMessage = error.localizedDescription
    }
}
