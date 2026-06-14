import SwiftUI

struct LiveStreamHeader: View {
    @Environment(MusaveraLabModel.self) private var analysisModel
    @Environment(LiveStreamModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 20) {
                    stateIcon
                    titleContent
                    Spacer(minLength: 24)
                    controls
                }

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 18) {
                        stateIcon
                        titleContent
                    }

                    controls
                }
            }

            Rectangle()
                .fill(LabTheme.separator)
                .frame(height: 1)

            HStack(spacing: 0) {
                LiveStreamFact(
                    title: "Duration",
                    value: formattedDuration,
                    systemImage: "timer"
                )

                factDivider

                LiveStreamFact(
                    title: "Sample Rate",
                    value: formattedSampleRate,
                    systemImage: "waveform"
                )

                factDivider

                LiveStreamFact(
                    title: "Channels",
                    value: formattedChannelCount,
                    systemImage: "speaker.wave.2"
                )

                factDivider

                LiveStreamFact(
                    title: "Buffers",
                    value: model.bufferCount.formatted(),
                    systemImage: "square.stack.3d.up"
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 232, alignment: .bottomLeading)
        .background(LabTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LabTheme.separator)
        }
    }

    private var stateIcon: some View {
        Image(systemName: model.state.systemImage)
            .font(.system(size: 38, weight: .medium))
            .foregroundStyle(model.state.tint)
            .frame(width: 88, height: 88)
            .background(
                LabTheme.accent.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 19)
            )
            .accessibilityHidden(true)
    }

    private var titleContent: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Live Stream")
                .font(.largeTitle.bold())

            Text("Hear loudness as audio reaches the microphone, then complete the musical analysis when capture ends.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 690, alignment: .leading)

            Label(model.state.title, systemImage: model.state.systemImage)
                .font(.callout.weight(.semibold))
                .foregroundStyle(model.state.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(model.state.tint.opacity(0.08), in: Capsule())
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
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)

                Text(
                    model.state == .requestingPermission
                        ? "Waiting for microphone access"
                        : "Completing the final analysis"
                )
                .font(.callout)
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
                .tint(LabTheme.accent)
                .controlSize(.large)
            }
        }
    }

    private var factDivider: some View {
        Rectangle()
            .fill(LabTheme.separator)
            .frame(width: 1, height: 38)
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

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
    }
}
