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
                    Label(section.title, systemImage: section.systemImage)
                        .tag(section)
                }
            }

            if selection == .analyze {
                Section("Sources") {
                    Button(action: onChooseMusic) {
                        SidebarActionLabel(
                            title: "Search Apple Music",
                            systemImage: "magnifyingglass"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isBusy)

                    Button(action: onImportAudio) {
                        SidebarActionLabel(
                            title: "Open Audio File",
                            systemImage: "folder"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isBusy)
                }

                Section("Apple Music") {
                    if model.isAuthorized {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                    } else {
                        Button {
                            Task {
                                await model.requestAuthorization()
                            }
                        } label: {
                            Label("Connect", systemImage: "person.crop.circle.badge.plus")
                        }
                        .disabled(model.isBusy)
                    }
                }
            } else {
                Section("Microphone") {
                    Label(
                        liveStreamModel.state.title,
                        systemImage: liveStreamModel.state.systemImage
                    )
                    .foregroundStyle(.secondary)

                    Label("Loudness while listening", systemImage: "waveform")
                        .foregroundStyle(.secondary)

                    Label("Full analysis after stop", systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Musavera Lab")
    }
}

private struct SidebarActionLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(LabTheme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
