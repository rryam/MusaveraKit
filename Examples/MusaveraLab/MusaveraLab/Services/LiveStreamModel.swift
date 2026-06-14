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
    private(set) var recordingURL: URL?
    var errorMessage: String?

    let recordingPlayer = PreviewPlayer()

    @ObservationIgnored private var audioEngine: AVAudioEngine?
    @ObservationIgnored private var captureSink: LiveAudioBufferSink?
    @ObservationIgnored private var recordingWriter: LiveRecordingWriter?
    @ObservationIgnored private var streamingSession: MusaveraStreamingSession?
    @ObservationIgnored private var analysisTask: Task<Void, Never>?
    @ObservationIgnored private var loudnessTask: Task<Void, Never>?
    @ObservationIgnored private var recordingLoadTask: Task<Void, Never>?
    @ObservationIgnored private var tapInstalled = false
    @ObservationIgnored private var capturedFrameCount: Int64 = 0

    isolated deinit {
        analysisTask?.cancel()
        loudnessTask?.cancel()
        recordingLoadTask?.cancel()
        captureSink?.finish()
        recordingWriter?.discard()

        if tapInstalled {
            audioEngine?.inputNode.removeTap(onBus: 0)
        }
        audioEngine?.stop()

        if let streamingSession {
            Task {
                await streamingSession.cancel()
            }
        }

        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
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
            || recordingURL != nil
            || errorMessage != nil
    }

    var isRecordingReady: Bool {
        recordingURL != nil && recordingPlayer.duration > 0
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

        state = .finalizing
        let progress = finishAudioProvider(retainRecording: true)

        guard progress.frameCount > 0 else {
            fail(with: LiveStreamError.noAudioCaptured)
            return
        }
    }

    func finishIfNeeded() {
        if state == .listening {
            stop()
        }
    }

    func toggleRecordingPlayback() {
        guard isRecordingReady else { return }

        if recordingPlayer.isPlaying {
            recordingPlayer.pause()
        } else {
            recordingPlayer.play()
        }
    }

    func pauseRecordingPlayback() {
        recordingPlayer.pause()
    }

    func reset() {
        cancelActiveSession(retainRecording: false)
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
        let sink = LiveAudioBufferSink(continuation: pair.continuation)
        let session = MusaveraStreamingSession(audioProvider: pair.stream)
        let writer = try LiveRecordingWriter(format: format)

        audioEngine = engine
        captureSink = sink
        recordingWriter = writer
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
            ) { [weak self, sink, writer] buffer, _ in
                writer.append(buffer)
                guard let progress = sink.yield(buffer) else { return }

                Task { @MainActor [weak self, sink] in
                    self?.receive(captureProgress: progress, from: sink)
                }
            }
            tapInstalled = true

            engine.prepare()
            try engine.start()
            state = .listening
        } catch {
            finishAudioProvider(retainRecording: false)
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
                self?.handleLoudnessFailure(error)
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

    private func receive(
        captureProgress: LiveCaptureProgress,
        from sink: LiveAudioBufferSink
    ) {
        guard captureSink === sink else { return }
        apply(captureProgress: captureProgress)
    }

    private func apply(captureProgress: LiveCaptureProgress) {
        capturedFrameCount = captureProgress.frameCount
        bufferCount = captureProgress.bufferCount
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
            finishAudioProvider(retainRecording: true)
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
        cancelActiveSession(retainRecording: false)
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
        clearRecording()
    }

    @discardableResult
    private func finishAudioProvider(retainRecording: Bool) -> LiveCaptureProgress {
        audioEngine?.stop()

        if tapInstalled {
            audioEngine?.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }

        let progress = captureSink?.finish()
            ?? LiveCaptureProgress(
                frameCount: capturedFrameCount,
                bufferCount: bufferCount
            )
        captureSink = nil
        audioEngine = nil
        apply(captureProgress: progress)
        finishRecording(
            retainRecording: retainRecording && progress.frameCount > 0
        )
        return progress
    }

    private func cancelActiveSession(retainRecording: Bool) {
        let session = streamingSession

        analysisTask?.cancel()
        loudnessTask?.cancel()
        analysisTask = nil
        loudnessTask = nil
        finishAudioProvider(retainRecording: retainRecording)
        streamingSession = nil

        if let session {
            Task {
                await session.cancel()
            }
        }
    }

    private func handleLoudnessFailure(_ error: any Error) {
        loudnessTask = nil

        guard state == .listening else { return }
        fail(with: error)
    }

    private func fail(with error: any Error) {
        let retainRecording = state == .listening || state == .finalizing
        cancelActiveSession(retainRecording: retainRecording)
        state = .idle
        errorMessage = error.localizedDescription
    }

    private func finishRecording(retainRecording: Bool) {
        guard let writer = recordingWriter else { return }
        recordingWriter = nil

        guard retainRecording else {
            writer.discard()
            return
        }

        do {
            prepareRecordingPlayback(at: try writer.finish())
        } catch {
            writer.discard()
            if errorMessage == nil {
                errorMessage = "The microphone recording could not be saved: \(error.localizedDescription)"
            }
        }
    }

    private func prepareRecordingPlayback(at url: URL) {
        recordingLoadTask?.cancel()
        recordingPlayer.unload()

        if let previousURL = recordingURL, previousURL != url {
            try? FileManager.default.removeItem(at: previousURL)
        }

        recordingURL = url
        recordingLoadTask = Task { [weak self] in
            guard let self else { return }
            await recordingPlayer.load(
                AVURLAsset(
                    url: url,
                    options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
                )
            )
            guard !Task.isCancelled else { return }
            recordingLoadTask = nil
        }
    }

    private func clearRecording() {
        recordingLoadTask?.cancel()
        recordingLoadTask = nil
        recordingPlayer.unload()
        recordingWriter?.discard()
        recordingWriter = nil

        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }
        recordingURL = nil
    }
}

private nonisolated struct LiveCaptureProgress: Sendable {
    var frameCount: Int64 = 0
    var bufferCount = 0
}

private nonisolated final class LiveAudioBufferSink: @unchecked Sendable {
    private let lock = NSLock()
    private let continuation: AsyncStream<AVReadOnlyAudioPCMBuffer>.Continuation
    private var progress = LiveCaptureProgress()
    private var isFinished = false

    init(continuation: AsyncStream<AVReadOnlyAudioPCMBuffer>.Continuation) {
        self.continuation = continuation
    }

    func yield(_ buffer: AVReadOnlyAudioPCMBuffer) -> LiveCaptureProgress? {
        lock.lock()
        defer { lock.unlock() }

        guard !isFinished else { return nil }

        switch continuation.yield(buffer) {
        case .enqueued:
            progress.frameCount += Int64(buffer.frameLength)
            progress.bufferCount += 1
            return progress
        case .dropped, .terminated:
            return nil
        @unknown default:
            return nil
        }
    }

    @discardableResult
    func finish() -> LiveCaptureProgress {
        lock.lock()
        defer { lock.unlock() }

        if !isFinished {
            isFinished = true
            continuation.finish()
        }

        return progress
    }
}

private nonisolated final class LiveRecordingWriter: @unchecked Sendable {
    let url: URL

    private let lock = NSLock()
    private var audioFile: AVAudioFile?
    private var writeError: (any Error)?
    private var isFinished = false

    init(format: AVAudioFormat) throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Musavera Recording \(UUID().uuidString)")
            .appendingPathExtension("caf")
        audioFile = try AVAudioFile(
            forWriting: url,
            settings: format.settings
        )
    }

    func append(_ buffer: AVReadOnlyAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }

        guard !isFinished, writeError == nil, let audioFile else { return }

        do {
            try audioFile.write(from: buffer)
        } catch {
            writeError = error
            self.audioFile = nil
        }
    }

    func finish() throws -> URL {
        lock.lock()
        isFinished = true
        audioFile = nil
        let error = writeError
        lock.unlock()

        if let error {
            throw error
        }
        return url
    }

    func discard() {
        lock.lock()
        isFinished = true
        audioFile = nil
        lock.unlock()

        try? FileManager.default.removeItem(at: url)
    }
}
