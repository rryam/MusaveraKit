import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(MusaveraLabModel.self) private var model
    @Environment(LiveStreamModel.self) private var liveStreamModel
    @State private var selection: LabSection = .analyze
    @State private var isImportingAudio = false
    @State private var isChoosingMusic = false

    var body: some View {
        NavigationSplitView {
            MusicBrowserSidebar(
                selection: $selection,
                onChooseMusic: {
                    isChoosingMusic = true
                },
                onImportAudio: {
                    isImportingAudio = true
                }
            )
            .navigationSplitViewColumnWidth(min: 240, ideal: 270, max: 340)
        } detail: {
            switch selection {
            case .analyze:
                AnalysisDetailContentView(
                    onChooseMusic: {
                        isChoosingMusic = true
                    },
                    onImportAudio: {
                        isImportingAudio = true
                    }
                )
            case .live:
                LiveStreamView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $isChoosingMusic) {
            MusicSelectionSheet()
        }
        .fileImporter(
            isPresented: $isImportingAudio,
            allowedContentTypes: [.audio]
        ) { result in
            importAudio(from: result)
        }
        .alert(
            "Musavera Lab",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        model.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK") {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            model.prepare()
        }
        .onChange(of: selection) { oldValue, newValue in
            if newValue == .live {
                model.pauseAllPlayback()
            } else if oldValue == .live {
                liveStreamModel.finishIfNeeded()
            }
        }
        .onDisappear {
            liveStreamModel.finishIfNeeded()
        }
    }

    private func importAudio(from result: Result<URL, any Error>) {
        guard case .success(let url) = result else { return }

        let isAccessing = url.startAccessingSecurityScopedResource()
        Task {
            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            await model.analyzeLocalFile(at: url)
        }
    }
}

private struct AnalysisDetailContentView: View {
    @Environment(MusaveraLabModel.self) private var model

    let onChooseMusic: () -> Void
    let onImportAudio: () -> Void

    var body: some View {
        ZStack {
            LabTheme.background
                .ignoresSafeArea()

            if let source = model.source, let analysis = model.analysis {
                AnalysisDashboard(
                    source: source,
                    analysis: analysis,
                    onChooseMusic: onChooseMusic
                )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else if model.isBusy {
                WorkingView(state: model.workState)
            } else {
                WelcomeDetailView(
                    onChooseMusic: onChooseMusic,
                    onImportAudio: onImportAudio
                )
            }
        }
        .animation(.smooth(duration: 0.35), value: model.analysis != nil)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.analysis != nil {
                TransportBar()
            }
        }
    }
}

private struct WelcomeDetailView: View {
    let onChooseMusic: () -> Void
    let onImportAudio: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Listen Deeper")
                        .font(.largeTitle.bold())

                    Text("Turn an Apple Music preview or local audio file into a synchronized map of the song.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 700, alignment: .leading)
                }

                GroupBox {
                    HStack(spacing: 22) {
                        Image(systemName: "waveform.path.ecg.rectangle")
                            .font(.system(size: 48, weight: .regular))
                            .foregroundStyle(.secondary)
                            .frame(width: 86, height: 86)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Choose your source")
                                .font(.title2.bold())

                            Text("Search Apple Music from the sidebar, or open an audio file already on this Mac. Musavera Lab downloads only the catalog preview for local analysis.")
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack {
                                Button("Choose Music", systemImage: "music.note.list") {
                                    onChooseMusic()
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Open Audio File", systemImage: "folder") {
                                    onImportAudio()
                                }
                            }
                            .padding(.top, 6)
                        }

                        Spacer()
                    }
                    .padding(8)
                }

                Text("What Musavera understands")
                    .font(.title2.bold())

                LazyVGrid(columns: columns, spacing: 12) {
                    CapabilityCard(
                        title: "Key",
                        detail: "Tonic and mode over time",
                        systemImage: "music.quarternote.3"
                    )
                    CapabilityCard(
                        title: "Rhythm",
                        detail: "Tempo, beats, and bars",
                        systemImage: "metronome"
                    )
                    CapabilityCard(
                        title: "Structure",
                        detail: "Sections, segments, and phrases",
                        systemImage: "square.3.layers.3d"
                    )
                    CapabilityCard(
                        title: "Pace",
                        detail: "Perceived musical motion",
                        systemImage: "speedometer"
                    )
                    CapabilityCard(
                        title: "Instruments",
                        detail: "Vocal, drum, bass, and other activity",
                        systemImage: "pianokeys"
                    )
                    CapabilityCard(
                        title: "Loudness",
                        detail: "Peak, integrated, and momentary levels",
                        systemImage: "waveform"
                    )
                }
            }
            .frame(maxWidth: 1_000, alignment: .leading)
            .padding(32)
        }
    }
}

private struct CapabilityCard: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        GroupBox {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
        }
    }
}

private struct WorkingView: View {
    let state: MusaveraLabModel.WorkState

    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)

            Text(state.title)
                .font(.title2.bold())

            if state == .analyzing {
                Text("The first analysis may take a moment. MusicUnderstanding is decoding the preview locally.")
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .padding(40)
    }
}
