import MusicKit
import SwiftUI

struct MusicBrowserSidebar: View {
    @Environment(MusaveraLabModel.self) private var model
    @Environment(LiveStreamModel.self) private var liveStreamModel
    @Binding var selection: LabSection
    let onChooseMusic: () -> Void
    let onImportAudio: () -> Void

    var body: some View {
        List(selection: $selection) {
            Section("Workspace") {
                ForEach(LabSection.allCases) { section in
                    VStack(alignment: .leading, spacing: 2) {
                        Label(section.title, systemImage: section.systemImage)
                            .font(.headline)

                        Text(section.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .padding(.leading, 24)
                    }
                    .padding(.vertical, 3)
                    .tag(section)
                }
            }

            if selection == .analyze {
                Section("Apple Music") {
                    if model.isAuthorized {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                    } else {
                        AuthorizationRow()
                    }

                    Button(action: onChooseMusic) {
                        Label("Choose Music", systemImage: "music.note.list")
                    }
                    .disabled(model.isBusy)
                }

                Section("On This Mac") {
                    Button(action: onImportAudio) {
                        Label("Open Audio File", systemImage: "folder")
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isBusy)
                }
            } else {
                Section("Microphone") {
                    Label(
                        liveStreamModel.state.title,
                        systemImage: liveStreamModel.state.systemImage
                    )
                    .foregroundStyle(.secondary)

                    Label("Loudness updates live", systemImage: "waveform")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Label("Music analysis after stop", systemImage: "checkmark.circle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Musavera Lab")
    }
}

private struct AuthorizationRow: View {
    @Environment(MusaveraLabModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Connect to search", systemImage: "music.note")
                .font(.headline)

            Text("Connect to search the catalog and play full songs. Preview analysis stays on this Mac.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Connect Apple Music") {
                Task {
                    await model.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isBusy)
        }
        .padding(.vertical, 4)
    }
}
