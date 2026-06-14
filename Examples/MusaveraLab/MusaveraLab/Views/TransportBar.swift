import SwiftUI

struct TransportBar: View {
    @Environment(MusaveraLabModel.self) private var model
    @Environment(PreviewPlayer.self) private var player

    var body: some View {
        @Bindable var bindablePlayer = player

        FloatingTransportSurface {
            HStack(spacing: 14) {
                if let source = model.source {
                    ArtworkView(url: source.artworkURL, size: 42)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(source.title)
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)

                        Text(source.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(width: 170, alignment: .leading)
                }

                Button {
                    model.togglePreviewPlayback()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.callout.weight(.semibold))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .keyboardShortcut(" ", modifiers: [])
                .accessibilityLabel(player.isPlaying ? "Pause preview" : "Play preview")

                Text(player.formattedCurrentTime)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 38, alignment: .trailing)

                Slider(
                    value: Binding(
                        get: { player.currentTime },
                        set: { player.seek(to: $0) }
                    ),
                    in: 0...max(player.duration, 0.01)
                )

                Text(player.formattedDuration)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 38, alignment: .leading)

                Divider()
                    .frame(height: 24)

                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)

                Slider(value: $bindablePlayer.volume, in: 0...1)
                    .frame(width: 92)
                    .accessibilityLabel("Preview volume")
            }
        }
    }
}

struct FloatingTransportSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
        .frame(maxWidth: 980)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}
