import SwiftUI

struct AnalyzeWelcomeView: View {
    let onChooseMusic: () -> Void
    let onImportAudio: () -> Void

    private let capabilityColumns = [
        GridItem(.adaptive(minimum: 250), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Analyze Music")
                        .font(.largeTitle.bold())

                    Text("Turn a song into a synchronized view of its key, rhythm, structure, instruments, and loudness.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 760, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Choose a Source")
                        .font(.title2.bold())

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 14) {
                            sourceButtons
                        }

                        VStack(spacing: 14) {
                            sourceButtons
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Analysis Includes")
                        .font(.title2.bold())

                    LazyVGrid(columns: capabilityColumns, spacing: 12) {
                        AnalysisCapability(
                            title: "Key",
                            detail: "Tonic and mode over time",
                            systemImage: "music.quarternote.3"
                        )
                        AnalysisCapability(
                            title: "Rhythm",
                            detail: "Tempo, beats, and bars",
                            systemImage: "metronome"
                        )
                        AnalysisCapability(
                            title: "Structure",
                            detail: "Sections, segments, and phrases",
                            systemImage: "square.3.layers.3d"
                        )
                        AnalysisCapability(
                            title: "Pace",
                            detail: "Perceived musical motion",
                            systemImage: "speedometer"
                        )
                        AnalysisCapability(
                            title: "Instruments",
                            detail: "Vocal, drum, bass, and other activity",
                            systemImage: "pianokeys"
                        )
                        AnalysisCapability(
                            title: "Loudness",
                            detail: "Peak, integrated, and momentary levels",
                            systemImage: "waveform"
                        )
                    }
                }
            }
            .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
            .padding(32)
        }
    }

    @ViewBuilder
    private var sourceButtons: some View {
        SourceOptionButton(
            title: "Search Apple Music",
            detail: "Analyze a 30-second catalog preview",
            systemImage: "music.note",
            isPrimary: true,
            action: onChooseMusic
        )

        SourceOptionButton(
            title: "Open Audio File",
            detail: "Analyze a song already on this Mac",
            systemImage: "waveform",
            isPrimary: false,
            action: onImportAudio
        )
    }
}

private struct SourceOptionButton: View {
    let title: String
    let detail: String
    let systemImage: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isPrimary ? LabTheme.accent.opacity(0.09) : LabTheme.surface)

                Image(systemName: systemImage)
                    .font(.system(size: 112, weight: .medium))
                    .foregroundStyle(
                        isPrimary
                            ? LabTheme.accent.opacity(0.09)
                            : Color.secondary.opacity(0.06)
                    )
                    .rotationEffect(.degrees(-9))
                    .offset(x: 118, y: 24)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: systemImage)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(isPrimary ? LabTheme.accent : .secondary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(title)
                        .font(.title2.bold())

                    Text(detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                .padding(20)
            }
            .frame(maxWidth: .infinity, minHeight: 168)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isPrimary
                            ? LabTheme.accent.opacity(0.16)
                            : LabTheme.separator
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint(detail)
    }
}

private struct AnalysisCapability: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.title3.weight(.medium))
                .foregroundStyle(LabTheme.accent)
                .frame(width: 36, height: 36)
                .background(LabTheme.accent.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(
            LabTheme.surface,
            in: RoundedRectangle(cornerRadius: LabTheme.sectionRadius, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}
