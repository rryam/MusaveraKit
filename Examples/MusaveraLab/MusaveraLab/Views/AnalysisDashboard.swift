import MusaveraKit
import SwiftUI
import UniformTypeIdentifiers

struct AnalysisDashboard: View {
    @Environment(MusaveraLabModel.self) private var model
    @State private var isExporting = false

    let source: MusaveraLabModel.AudioSource
    let analysis: MusaveraAnalysis
    let onChooseMusic: () -> Void

    private let summaryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let activityColumns = [
        GridItem(.adaptive(minimum: 220, maximum: 360), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SourceHeader(
                    source: source,
                    onExport: exportAnalysis,
                    onChooseMusic: onChooseMusic
                )

                Text("Analysis")
                    .font(.title2.bold())
                    .padding(.top, 4)

                LazyVGrid(columns: summaryColumns, spacing: 12) {
                    AnalysisTile(title: "Key", systemImage: "music.quarternote.3") {
                        KeySummaryView(key: analysis.key)
                    }

                    AnalysisTile(title: "Rhythm", systemImage: "metronome") {
                        RhythmSummaryView(rhythm: analysis.rhythm)
                    }
                }

                if let structure = analysis.structure {
                    AnalysisTile(title: "Structure", systemImage: "square.3.layers.3d") {
                        StructureTimeline(result: structure)
                            .frame(height: 88)
                            .playheadOverlay()
                    }
                }

                if let pace = analysis.pace {
                    AnalysisTile(title: "Pace", systemImage: "speedometer") {
                        PaceChart(result: pace)
                            .frame(height: 150)
                            .playheadOverlay()
                    }
                }

                if let instruments = analysis.instrumentActivity {
                    AnalysisTile(title: "Instrument Ranges", systemImage: "pianokeys") {
                        InstrumentRangesChart(result: instruments)
                            .frame(height: 190)
                            .playheadOverlay()
                    }

                    LazyVGrid(columns: activityColumns, spacing: 12) {
                        ForEach(InstrumentActivityResult.Instrument.labOrder, id: \.rawValue) { instrument in
                            AnalysisTile(
                                title: "\(instrument.rawValue.capitalized) Activity",
                                systemImage: instrument.systemImage
                            ) {
                                InstrumentActivityChart(
                                    values: instruments.activity(for: instrument),
                                    color: instrument.labColor
                                )
                                .frame(height: 110)
                                .playheadOverlay()
                            }
                        }
                    }
                }

                if let loudness = analysis.loudness {
                    AnalysisTile(title: "Loudness", systemImage: "waveform") {
                        LoudnessAnalysisView(result: loudness)
                    }
                }
            }
            .frame(maxWidth: 1_400, alignment: .leading)
            .padding(28)
        }
        .fileExporter(
            isPresented: $isExporting,
            document: AnalysisJSONDocument(analysis: analysis),
            contentType: .json,
            defaultFilename: source.exportFilename
        ) { result in
            switch result {
            case .success:
                model.errorMessage = nil
            case .failure(let error):
                model.errorMessage = "The analysis could not be exported: \(error.localizedDescription)"
            }
        }
    }

    private func exportAnalysis() {
        model.errorMessage = nil
        isExporting = true
    }
}

private struct SourceHeader: View {
    @Environment(MusaveraLabModel.self) private var model

    let source: MusaveraLabModel.AudioSource
    let onExport: () -> Void
    let onChooseMusic: () -> Void

    var body: some View {
        HStack(spacing: source.artworkURL == nil ? 20 : 24) {
            ArtworkView(
                url: source.artworkURL,
                size: source.artworkURL == nil ? 116 : 152
            )
                .shadow(color: .black.opacity(0.16), radius: 12, y: 6)

            VStack(alignment: .leading, spacing: 7) {
                Text(source.title)
                    .font(.largeTitle.bold())
                    .lineLimit(2)

                Text(source.subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Label(
                    source.isAppleMusicPreview ? "30-second Apple Music preview" : "Local audio",
                    systemImage: source.isAppleMusicPreview ? "clock" : "internaldrive"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                if model.selectedSong != nil {
                    Button {
                        Task {
                            await model.toggleFullSongPlayback()
                        }
                    } label: {
                        Label(
                            model.isFullSongPlaybackActive ? "Pause Full Song" : "Play Full Song",
                            systemImage: model.isFullSongPlaybackActive ? "pause.fill" : "music.note"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Export JSON", systemImage: "square.and.arrow.up", action: onExport)
                    .buttonStyle(.bordered)

                Button {
                    onChooseMusic()
                } label: {
                    Label("Find Music", systemImage: "magnifyingglass")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, source.artworkURL == nil ? 2 : 8)
    }
}
