import CoreMedia
import MusicUnderstanding
import MusaveraKit
import SwiftUI

struct ArtworkView: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                ZStack {
                    LabTheme.card

                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.34, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .stroke(LabTheme.cardBorder)
        }
    }
}

struct AnalysisTile<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        GroupBox {
            content
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline)
        }
        .accessibilityElement(children: .contain)
    }
}

struct KeySummaryView: View {
    let key: KeyResult?

    var body: some View {
        VStack(spacing: 2) {
            Text(key?.primarySignature?.tonic.musaveraDescription ?? "--")
                .font(.system(size: 54, weight: .bold, design: .rounded))

            Text(key?.primarySignature?.mode.rawValue.capitalized ?? "No key detected")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(height: 92)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(key?.primarySignature?.musaveraDescription ?? "No key detected")
    }
}

struct RhythmSummaryView: View {
    @Environment(PreviewPlayer.self) private var player

    let rhythm: RhythmResult?

    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 0) {
                Text(rhythm?.beatsPerMinute.map { Int($0).formatted() } ?? "--")
                    .font(.system(size: 52, weight: .bold, design: .rounded))

                Text("BPM")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 7) {
                ForEach(0..<4, id: \.self) { beat in
                    Capsule()
                        .fill(
                            Color.accentColor.opacity(
                                isActive(beat: beat) ? 0.9 : beat == 0 ? 0.34 : 0.14
                            )
                        )
                        .frame(width: 25, height: 8)
                }
            }
        }
        .frame(height: 92)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            rhythm?.beatsPerMinute.map { "\(Int($0)) beats per minute" }
            ?? "No tempo detected"
        )
    }

    private func isActive(beat: Int) -> Bool {
        guard player.isPlaying, let beats = rhythm?.beats, !beats.isEmpty else {
            return false
        }

        let completedBeatCount = beats.prefix { $0.seconds <= player.currentTime }.count
        return completedBeatCount > 0 && (completedBeatCount - 1) % 4 == beat
    }
}
