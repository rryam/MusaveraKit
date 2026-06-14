import AppKit
import MusaveraKit
import SwiftUI
import UniformTypeIdentifiers

struct LiveStreamView: View {
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
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(maxWidth: 1_300, alignment: .leading)
                .padding(28)
            }
        }
        .animation(.smooth(duration: 0.3), value: model.state)
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
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.orange.opacity(0.24))
        }
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
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            LiveCapabilityCard(
                title: "While Listening",
                detail: "Momentary, short-term, integrated, and peak loudness update from incoming PCM buffers.",
                systemImage: "waveform",
                tint: .red
            )

            LiveCapabilityCard(
                title: "After You Stop",
                detail: "Music Understanding finishes key, tempo, structure, pace, instruments, and final loudness.",
                systemImage: "waveform.path.ecg",
                tint: .indigo
            )

            LiveCapabilityCard(
                title: "Audio Boundary",
                detail: "This tab analyzes microphone PCM. MusicKit playback does not expose full-song PCM to apps.",
                systemImage: "lock.shield",
                tint: .blue
            )
        }
    }
}

private struct LiveCapabilityCard: View {
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)

                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        }
    }
}
