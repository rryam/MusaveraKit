import SwiftUI

struct LiveStreamHeader: View {
    @Environment(MusaveraLabModel.self) private var analysisModel
    @Environment(LiveStreamModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(model.state.tint.opacity(0.12))

                    Image(systemName: model.state.systemImage)
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(model.state.tint)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(width: 92, height: 92)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Live Stream")
                        .font(.largeTitle.bold())

                    Text("Analyze audio as it reaches the microphone, then finish the complete musical picture when capture ends.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Label(model.state.title, systemImage: model.state.systemImage)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(model.state.tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(model.state.tint.opacity(0.1), in: Capsule())
                }

                Spacer(minLength: 20)

                controls
            }

            Divider()

            HStack(spacing: 0) {
                LiveStreamFact(
                    title: "Duration",
                    value: formattedDuration,
                    systemImage: "timer"
                )

                LiveStreamFact(
                    title: "Sample Rate",
                    value: formattedSampleRate,
                    systemImage: "waveform"
                )

                LiveStreamFact(
                    title: "Channels",
                    value: formattedChannelCount,
                    systemImage: "speaker.wave.2"
                )

                LiveStreamFact(
                    title: "Buffers",
                    value: model.bufferCount.formatted(),
                    systemImage: "square.stack.3d.up"
                )
            }
        }
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(LabTheme.cardBorder)
        }
    }

    @ViewBuilder
    private var controls: some View {
        if model.state == .listening {
            Button {
                model.stop()
            } label: {
                Label("Stop & Analyze", systemImage: "stop.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)
        } else if model.isWorking {
            VStack(alignment: .trailing, spacing: 8) {
                ProgressView()
                    .controlSize(.small)

                Text(
                    model.state == .requestingPermission
                        ? "Waiting for microphone access"
                        : "Completing the final analysis"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } else {
            HStack(spacing: 10) {
                if model.canReset {
                    Button("Reset", systemImage: "arrow.counterclockwise") {
                        model.reset()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button {
                    analysisModel.pauseAllPlayback()
                    Task {
                        await model.start()
                    }
                } label: {
                    Label(
                        model.state == .complete ? "Listen Again" : "Start Listening",
                        systemImage: "mic.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var formattedDuration: String {
        let totalSeconds = Int(model.elapsedTime.rounded(.down))
        return String(
            format: "%02d:%02d",
            totalSeconds / 60,
            totalSeconds % 60
        )
    }

    private var formattedSampleRate: String {
        guard model.sampleRate > 0 else { return "--" }
        return String(format: "%.1f kHz", model.sampleRate / 1_000)
    }

    private var formattedChannelCount: String {
        switch model.channelCount {
        case 0:
            "--"
        case 1:
            "Mono"
        case 2:
            "Stereo"
        default:
            "\(model.channelCount)"
        }
    }
}

private struct LiveStreamFact: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline.monospacedDigit())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
    }
}
