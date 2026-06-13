import MusicKit
import SwiftUI

struct MusicBrowserSidebar: View {
    @Environment(MusaveraLabModel.self) private var model
    let onChooseMusic: () -> Void
    let onImportAudio: () -> Void

    var body: some View {
        List {
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
