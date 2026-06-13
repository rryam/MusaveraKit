@preconcurrency import AVFoundation
import Foundation
@preconcurrency import MusicKit
import MusaveraKit
import Observation

@Observable
@MainActor
final class MusaveraLabModel {
    struct AudioSource {
        let title: String
        let subtitle: String
        let artworkURL: URL?
        let localURL: URL
        let isAppleMusicPreview: Bool

        var exportFilename: String {
            let filename = "\(title) - \(subtitle) Analysis"
            let disallowedCharacters = CharacterSet(charactersIn: "/:")
            return filename
                .components(separatedBy: disallowedCharacters)
                .joined(separator: "-")
        }
    }

    enum WorkState {
        case idle
        case authorizing
        case searching
        case downloading
        case importing
        case analyzing

        var title: String {
            switch self {
            case .idle:
                ""
            case .authorizing:
                "Connecting to Apple Music"
            case .searching:
                "Searching the Apple Music catalog"
            case .downloading:
                "Downloading the 30-second preview"
            case .importing:
                "Preparing the audio file"
            case .analyzing:
                "Listening for key, rhythm, structure, and texture"
            }
        }
    }

    var authorizationStatus = MusicAuthorization.currentStatus
    var selectedSong: Song?
    var source: AudioSource?
    var analysis: MusaveraAnalysis?
    var workState: WorkState = .idle
    var errorMessage: String?

    let previewPlayer = PreviewPlayer()

    @ObservationIgnored private let fileStore = AudioFileStore()
    @ObservationIgnored private let fullSongPlayer = ApplicationMusicPlayer.shared

    var isBusy: Bool {
        workState != .idle
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    func prepare() {
        authorizationStatus = MusicAuthorization.currentStatus
    }

    func requestAuthorization() async {
        guard workState == .idle else { return }

        errorMessage = nil
        workState = .authorizing
        authorizationStatus = await MusicAuthorization.request()
        workState = .idle

        guard authorizationStatus == .authorized else {
            errorMessage = "Apple Music access is required for catalog search. Local audio analysis still works without it."
            return
        }
    }

    func analyze(song: Song) async {
        guard workState == .idle else { return }

        errorMessage = nil
        selectedSong = song
        analysis = nil
        source = nil
        previewPlayer.stop()
        fullSongPlayer.pause()

        do {
            guard let previewURL = song.previewAssets?.compactMap(\.url).first else {
                throw LabError.previewUnavailable
            }

            workState = .downloading
            let localURL = try await fileStore.download(
                previewURL,
                identifier: song.id.rawValue
            )

            try await analyzeAudio(
                at: localURL,
                title: song.title,
                subtitle: song.artistName,
                artworkURL: song.artwork?.url(width: 640, height: 640),
                isAppleMusicPreview: true
            )
        } catch {
            fail(with: error)
        }
    }

    func analyzeLocalFile(at sourceURL: URL) async {
        guard workState == .idle else { return }

        errorMessage = nil
        selectedSong = nil
        analysis = nil
        source = nil
        previewPlayer.stop()
        fullSongPlayer.pause()
        workState = .importing

        do {
            let localURL = try await fileStore.importFile(sourceURL)
            try await analyzeAudio(
                at: localURL,
                title: displayTitle(for: sourceURL),
                subtitle: "Local audio file",
                artworkURL: nil,
                isAppleMusicPreview: false
            )
        } catch {
            fail(with: error)
        }
    }

    func playFullSong() async {
        guard let selectedSong else { return }

        errorMessage = nil
        previewPlayer.pause()

        do {
            fullSongPlayer.queue = ApplicationMusicPlayer.Queue(for: [selectedSong])
            try await fullSongPlayer.play()
        } catch {
            errorMessage = "Full-song playback could not start: \(error.localizedDescription)"
        }
    }

    func reset() {
        previewPlayer.unload()
        fullSongPlayer.pause()
        selectedSong = nil
        source = nil
        analysis = nil
        workState = .idle
        errorMessage = nil
    }

    private func analyzeAudio(
        at url: URL,
        title: String,
        subtitle: String,
        artworkURL: URL?,
        isAppleMusicPreview: Bool
    ) async throws {
        let asset = AVURLAsset(
            url: url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )

        let isProtected = try await asset.load(.hasProtectedContent)
        guard !isProtected else {
            throw LabError.protectedContent
        }

        source = AudioSource(
            title: title,
            subtitle: subtitle,
            artworkURL: artworkURL,
            localURL: url,
            isAppleMusicPreview: isAppleMusicPreview
        )
        workState = .analyzing

        async let playerLoad: Void = previewPlayer.load(asset)
        let result: MusaveraAnalysis
        do {
            result = try await Musavera.analyze(asset: asset)
        } catch {
            await playerLoad
            throw error
        }
        await playerLoad

        analysis = result
        workState = .idle
    }

    private func displayTitle(for url: URL) -> String {
        let stem = url.deletingPathExtension().lastPathComponent
        let words = stem
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(whereSeparator: \.isWhitespace)

        guard !words.isEmpty else { return "Local Audio" }
        return words.map { $0.capitalized }.joined(separator: " ")
    }

    private func fail(with error: Error) {
        previewPlayer.unload()
        fullSongPlayer.pause()
        selectedSong = nil
        source = nil
        analysis = nil
        workState = .idle
        errorMessage = error.localizedDescription
    }
}

private enum LabError: LocalizedError {
    case previewUnavailable
    case protectedContent

    var errorDescription: String? {
        switch self {
        case .previewUnavailable:
            "Apple Music does not provide an analyzable preview for this song. Try another result."
        case .protectedContent:
            "This audio is DRM-protected and cannot be decoded by MusicUnderstanding."
        }
    }
}
