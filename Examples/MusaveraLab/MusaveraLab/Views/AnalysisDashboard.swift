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
        GridItem(.adaptive(minimum: 280), spacing: 12)
    ]

    private let activityColumns = [
        GridItem(.adaptive(minimum: 330, maximum: 660), spacing: 12)
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Color.clear
                        .frame(height: 0)
                        .id("analysis-top")

                    SourceHeader(
                        source: source,
                        onExport: exportAnalysis,
                        onChooseMusic: onChooseMusic
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Song Analysis")
                            .font(.title2.bold())

                        Text("Explore the musical details across the preview timeline.")
                            .foregroundStyle(.secondary)
                    }

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
                .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
                .padding(32)
            }
            .task(id: source.localURL) {
                await Task.yield()
                proxy.scrollTo("analysis-top", anchor: .top)
            }
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
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .bottom, spacing: 24) {
                artwork
                metadata
                Spacer(minLength: 20)
                actions
            }

            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .bottom, spacing: 20) {
                    artwork
                    metadata
                }

                actions
            }
        }
        .padding(24)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .bottomLeading)
        .background {
            SourceHeroBackground(artworkURL: source.artworkURL)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var artwork: some View {
        ArtworkView(
            url: source.artworkURL,
            size: source.artworkURL == nil ? 124 : 164
        )
        .shadow(color: .black.opacity(0.28), radius: 18, y: 9)
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(
                source.isAppleMusicPreview ? "APPLE MUSIC PREVIEW" : "LOCAL AUDIO",
                systemImage: source.isAppleMusicPreview ? "music.note" : "internaldrive"
            )
            .font(.caption.weight(.bold))
            .foregroundStyle(.white.opacity(0.72))

            Text(source.title)
                .font(.largeTitle.bold())
                .lineLimit(2)

            Text(source.subtitle)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(2)

            if source.isAppleMusicPreview {
                Label("30-second preview", systemImage: "clock")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                actionButtons
            }

            VStack(alignment: .leading, spacing: 10) {
                actionButtons
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if model.selectedSong != nil {
            Button {
                Task {
                    await model.toggleFullSongPlayback()
                }
            } label: {
                Label(
                    model.isFullSongPlaybackActive ? "Pause Full Song" : "Play Full Song",
                    systemImage: model.isFullSongPlaybackActive ? "pause.fill" : "play.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(LabTheme.accent)
            .controlSize(.large)
        }

        Button("Find Music", systemImage: "magnifyingglass") {
            onChooseMusic()
        }
        .buttonStyle(.bordered)
        .tint(.white)
        .controlSize(.large)

        Button("Export JSON", systemImage: "square.and.arrow.up", action: onExport)
            .buttonStyle(.bordered)
            .tint(.white)
            .controlSize(.large)
    }
}

private struct SourceHeroBackground: View {
    let artworkURL: URL?

    var body: some View {
        ZStack {
            Color.black.opacity(0.86)

            if let artworkURL {
                AsyncImage(url: artworkURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(1.12)
                            .blur(radius: 28)
                            .opacity(0.68)
                    }
                }
            }

            LinearGradient(
                colors: [
                    .black.opacity(0.08),
                    .black.opacity(0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
