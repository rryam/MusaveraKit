import AppKit
import MusaveraKit
import SwiftUI
import UniformTypeIdentifiers

struct LiveStreamView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(LiveStreamModel.self) private var model
    @State private var isExporting = false

    var body: some View {
        ZStack {
            LabTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    LiveStreamHeader()

                    if let errorMessage = model.errorMessage {
                        LiveStreamErrorBanner(
                            message: errorMessage,
                            showsSettingsButton: model.microphonePermissionDenied
                        )
                    }

                    LiveLoudnessView()

                    LiveAnalysisBoundaryView()

                    if let analysis = model.finalAnalysis {
                        LiveFinalAnalysisView(
                            analysis: analysis,
                            onExport: {
                                isExporting = true
                            }
                        )
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .opacity.combined(with: .move(edge: .bottom))
                        )
                    }
                }
                .frame(maxWidth: LabTheme.contentWidth, alignment: .leading)
                .padding(32)
            }
        }
        .animation(
            reduceMotion ? nil : .smooth(duration: 0.3),
            value: model.state
        )
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.recordingURL != nil {
                LiveRecordingTransport()
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .opacity.combined(with: .move(edge: .bottom))
                    )
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "Live Stream Analysis"
        ) { result in
            if case .failure(let error) = result {
                model.errorMessage = "The live analysis could not be exported: \(error.localizedDescription)"
            }
        }
    }

    private var exportDocument: AnalysisJSONDocument? {
        model.finalAnalysis.map(AnalysisJSONDocument.init(analysis:))
    }
}

private struct LiveStreamErrorBanner: View {
    @Environment(LiveStreamModel.self) private var model

    let message: String
    let showsSettingsButton: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 8) {
                Text("Live Stream Needs Attention")
                    .font(.headline)

                Text(message)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if showsSettingsButton {
                    Button("Open Microphone Settings", systemImage: "gear") {
                        openMicrophoneSettings()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()

            Button {
                model.errorMessage = nil
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(16)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }

    private func openMicrophoneSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

private struct LiveAnalysisBoundaryView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 250), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How Streaming Works")
                .font(.title2.bold())

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                LiveCapabilityCard(
                    title: "While Listening",
                    detail: "Momentary, short-term, integrated, and peak loudness update from incoming PCM buffers.",
                    systemImage: "waveform"
                )

                LiveCapabilityCard(
                    title: "After You Stop",
                    detail: "Music Understanding finishes key, tempo, structure, pace, instruments, and final loudness.",
                    systemImage: "waveform.path.ecg"
                )

                LiveCapabilityCard(
                    title: "Audio Boundary",
                    detail: "This tab analyzes microphone PCM. MusicKit playback does not expose full-song PCM to apps.",
                    systemImage: "lock.shield"
                )
            }
        }
    }
}

private struct LiveCapabilityCard: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.medium))
                .foregroundStyle(LabTheme.accent)
                .frame(width: 36, height: 36)
                .background(LabTheme.accent.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 102, alignment: .topLeading)
        .background(
            LabTheme.surface,
            in: RoundedRectangle(cornerRadius: LabTheme.sectionRadius, style: .continuous)
        )
    }
}
