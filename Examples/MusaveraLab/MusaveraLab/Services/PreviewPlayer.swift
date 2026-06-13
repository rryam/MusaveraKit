@preconcurrency import AVFoundation
import CoreMedia
import Foundation
import Observation

@Observable
@MainActor
final class PreviewPlayer {
    let player = AVPlayer()

    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private(set) var sampleRate: CMTimeScale = 44_100

    var volume: Float = 1 {
        didSet {
            player.volume = volume
        }
    }

    @ObservationIgnored private var endOfPlaybackTask: Task<Void, Never>?
    @ObservationIgnored private var timeObserver: Any?

    init() {
        installTimeObserver()
    }

    isolated deinit {
        endOfPlaybackTask?.cancel()
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }

    func load(_ asset: AVURLAsset) async {
        stop()

        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        observeEndOfPlayback(for: item)

        async let durationLoad = asset.load(.duration)
        async let tracksLoad = asset.loadTracks(withMediaType: .audio)

        if let assetDuration = try? await durationLoad, assetDuration.isNumeric {
            duration = assetDuration.seconds
        }

        if let audioTrack = try? await tracksLoad.first,
           let formatDescription = try? await audioTrack.load(.formatDescriptions).first,
           let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
            sampleRate = CMTimeScale(streamDescription.pointee.mSampleRate)
        }
    }

    func play() {
        player.play()
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func togglePlayback() {
        isPlaying ? pause() : play()
    }

    func stop() {
        pause()
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = 0
    }

    func seek(to seconds: Double) {
        let clampedSeconds = min(max(seconds, 0), duration)
        let time = CMTime(seconds: clampedSeconds, preferredTimescale: sampleRate)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clampedSeconds
    }

    var formattedCurrentTime: String {
        format(currentTime)
    }

    var formattedDuration: String {
        format(duration)
    }

    private func observeEndOfPlayback(for item: AVPlayerItem) {
        endOfPlaybackTask?.cancel()
        endOfPlaybackTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: AVPlayerItem.didPlayToEndTimeNotification,
                object: item
            ) {
                guard let self else { continue }
                self.stop()
            }
        }
    }

    private func installTimeObserver() {
        let interval = CMTime(seconds: 0.05, preferredTimescale: sampleRate)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self, time.seconds.isFinite else { return }
                self.currentTime = time.seconds
                self.isPlaying = self.player.rate != 0
            }
        }
    }

    private func format(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }
        return String(format: "%02d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}
