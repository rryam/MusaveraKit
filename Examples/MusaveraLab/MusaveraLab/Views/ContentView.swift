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
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
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
        .navigationSplitViewStyle(.prominentDetail)
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
                get: { presentedErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        dismissPresentedError()
                    }
                }
            )
        ) {
            Button("OK") {
                dismissPresentedError()
            }
        } message: {
            Text(presentedErrorMessage ?? "")
        }
        .task {
            model.prepare()
        }
        .onChange(of: selection) { oldValue, newValue in
            if newValue == .live {
                model.pauseAllPlayback()
            } else if oldValue == .live {
                liveStreamModel.deactivate()
            }
        }
        .onDisappear {
            liveStreamModel.deactivate()
        }
    }

    private var presentedErrorMessage: String? {
        if let errorMessage = model.errorMessage {
            errorMessage
        } else if selection != .live {
            liveStreamModel.errorMessage
        } else {
            nil
        }
    }

    private func dismissPresentedError() {
        if model.errorMessage != nil {
            model.errorMessage = nil
        } else {
            liveStreamModel.errorMessage = nil
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                .transition(
                    reduceMotion
                        ? .opacity
                        : .opacity.combined(with: .scale(scale: 0.985))
                )
            } else if model.isBusy {
                WorkingView(state: model.workState)
            } else {
                AnalyzeWelcomeView(
                    onChooseMusic: onChooseMusic,
                    onImportAudio: onImportAudio
                )
            }
        }
        .animation(
            reduceMotion ? nil : .smooth(duration: 0.35),
            value: model.analysis != nil
        )
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.analysis != nil {
                TransportBar()
            }
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
