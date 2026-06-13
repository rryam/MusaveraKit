import MusicKit
import SwiftUI

struct MusicSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MusaveraLabModel.self) private var model

    @State private var query = ""
    @State private var songs: [Song] = []
    @State private var isSearching = false
    @State private var searchMessage: String?
    @State private var activeSearchID: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if !model.isAuthorized {
                    ContentUnavailableView {
                        Label("Connect Apple Music", systemImage: "music.note")
                    } description: {
                        Text("Catalog search requires Apple Music access.")
                    } actions: {
                        Button("Connect") {
                            Task {
                                await model.requestAuthorization()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView(
                        "Search Apple Music",
                        systemImage: "music.note.list",
                        description: Text("Find a song to analyze its 30-second catalog preview.")
                    )
                } else if isSearching && songs.isEmpty {
                    ProgressView("Searching Apple Music")
                        .controlSize(.large)
                } else if songs.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text(searchMessage ?? "Try another song or artist.")
                    )
                } else {
                    List(songs) { song in
                        MusicSelectionRow(song: song) {
                            select(song)
                        }
                        .disabled(model.isBusy)
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("Choose Music")
            .searchable(
                text: $query,
                placement: .toolbar,
                prompt: "Song or artist"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 680, minHeight: 540)
        .task(id: SearchContext(query: query, isAuthorized: model.isAuthorized)) {
            await search()
        }
    }

    private func select(_ song: Song) {
        guard !model.isBusy else { return }

        dismiss()
        Task {
            await model.analyze(song: song)
        }
    }

    private func search() async {
        let searchID = UUID()
        activeSearchID = searchID
        defer {
            if activeSearchID == searchID {
                isSearching = false
            }
        }

        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard model.isAuthorized, !term.isEmpty else {
            songs = []
            searchMessage = nil
            return
        }

        isSearching = true
        songs = []
        searchMessage = nil

        do {
            try await Task.sleep(for: .milliseconds(350))

            var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
            request.limit = 25
            let response = try await request.response()
            try Task.checkCancellation()

            guard activeSearchID == searchID else { return }
            songs = Array(response.songs)
            searchMessage = songs.isEmpty ? "Nothing matched “\(term)”." : nil
        } catch is CancellationError {
            return
        } catch {
            guard activeSearchID == searchID else { return }
            songs = []
            searchMessage = error.localizedDescription
        }
    }
}

private struct SearchContext: Hashable {
    let query: String
    let isAuthorized: Bool
}

private struct MusicSelectionRow: View {
    let song: Song
    let action: () -> Void

    private var hasPreview: Bool {
        song.previewAssets?.contains(where: { $0.url != nil }) == true
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ArtworkView(
                    url: song.artwork?.url(width: 144, height: 144),
                    size: 58
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(song.artistName)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Label(
                        hasPreview ? "Preview available" : "Preview unavailable",
                        systemImage: hasPreview ? "waveform" : "exclamationmark.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!hasPreview)
        .padding(.vertical, 3)
        .accessibilityLabel(
            hasPreview
            ? "Analyze \(song.title) by \(song.artistName)"
            : "\(song.title) by \(song.artistName), preview unavailable"
        )
    }
}
