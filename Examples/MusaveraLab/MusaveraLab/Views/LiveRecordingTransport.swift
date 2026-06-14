import SwiftUI

struct LiveRecordingTransport: View {
    @Environment(MusaveraLabModel.self) private var analysisModel
    @Environment(LiveStreamModel.self) private var model

    var body: some View {
        @Bindable var player = model.recordingPlayer

        FloatingTransportSurface {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    recordingIdentity

                    Divider()
                        .frame(height: 34)

                    playbackControls(player: player)

                    Divider()
                        .frame(height: 34)

                    volumeControl(player: player)
                }

                VStack(alignment: .leading, spacing: 14) {
                    recordingIdentity
                    playbackControls(player: player)
                    volumeControl(player: player)
                }
            }
        }
    }

    private var recordingIdentity: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.title3.weight(.medium))
                .foregroundStyle(LabTheme.accent)
                .frame(width: 42, height: 42)
                .background(LabTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("Microphone Recording")
                    .font(.headline)

                Text("Captured during this live analysis")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 220, alignment: .leading)
    }

    private func playbackControls(player: PreviewPlayer) -> some View {
        HStack(spacing: 12) {
            if player.duration > 0 {
                Button {
                    if !player.isPlaying {
                        analysisModel.pauseAllPlayback()
                    }
                    model.toggleRecordingPlayback()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.callout.weight(.semibold))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .keyboardShortcut(" ", modifiers: [])
                .accessibilityLabel(
                    player.isPlaying ? "Pause microphone recording" : "Play microphone recording"
                )
            } else {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 34, height: 34)
                    .accessibilityLabel("Preparing microphone recording")
            }

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
            .disabled(player.duration <= 0)
            .frame(minWidth: 180)
            .accessibilityLabel("Recording position")

            Text(player.formattedDuration)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 38, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private func volumeControl(player: PreviewPlayer) -> some View {
        HStack(spacing: 8) {
            Image(systemName: player.volume == 0 ? "speaker.slash.fill" : "speaker.fill")
                .foregroundStyle(.secondary)

            Slider(
                value: Binding(
                    get: { player.volume },
                    set: { player.volume = $0 }
                ),
                in: 0...1
            )
            .frame(width: 96)
            .accessibilityLabel("Recording volume")
        }
    }
}
