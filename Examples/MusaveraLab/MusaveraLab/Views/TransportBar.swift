import SwiftUI

struct TransportBar: View {
    @Environment(MusaveraLabModel.self) private var model
    @Environment(PreviewPlayer.self) private var player

    var body: some View {
        @Bindable var bindablePlayer = player

        HStack(spacing: 16) {
            Button {
                model.togglePreviewPlayback()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.body.weight(.semibold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .keyboardShortcut(" ", modifiers: [])
            .accessibilityLabel(player.isPlaying ? "Pause preview" : "Play preview")

            Text(player.formattedCurrentTime)
                .font(.callout.monospacedDigit())
                .frame(width: 44, alignment: .trailing)

            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: $0) }
                ),
                in: 0...max(player.duration, 0.01)
            )

            Text(player.formattedDuration)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            Image(systemName: "speaker.fill")
                .foregroundStyle(.secondary)

            Slider(value: $bindablePlayer.volume, in: 0...1)
                .frame(width: 110)
                .accessibilityLabel("Preview volume")
        }
        .frame(maxWidth: 760)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(LabTheme.cardBorder)
        }
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
    }
}
