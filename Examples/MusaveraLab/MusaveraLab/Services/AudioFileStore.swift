import Foundation

actor AudioFileStore {
    enum StoreError: LocalizedError {
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                "The Apple Music preview server returned an invalid response."
            }
        }
    }

    private let fileManager = FileManager.default
    private let directory: URL

    init() {
        directory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0]
        .appending(path: "MusaveraLab", directoryHint: .isDirectory)
    }

    func download(_ remoteURL: URL, identifier: String) async throws -> URL {
        let (temporaryURL, response) = try await URLSession.shared.download(from: remoteURL)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw StoreError.invalidResponse
        }

        let destination = try destinationURL(
            identifier: identifier,
            sourceURL: remoteURL,
            defaultExtension: "m4a"
        )
        try replaceItem(at: destination, with: temporaryURL, copy: false)
        return destination
    }

    func importFile(_ sourceURL: URL) throws -> URL {
        let isAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let destination = try destinationURL(
            identifier: UUID().uuidString,
            sourceURL: sourceURL,
            defaultExtension: "audio"
        )
        try replaceItem(at: destination, with: sourceURL, copy: true)
        return destination
    }

    private func destinationURL(
        identifier: String,
        sourceURL: URL,
        defaultExtension: String
    ) throws -> URL {
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let safeIdentifier = String(
            identifier.map { character in
                character.isLetter || character.isNumber ? character : "-"
            }
        )
        let pathExtension = sourceURL.pathExtension.isEmpty
            ? defaultExtension
            : sourceURL.pathExtension

        return directory
            .appending(path: String(safeIdentifier.prefix(80)))
            .appendingPathExtension(pathExtension)
    }

    private func replaceItem(at destination: URL, with source: URL, copy: Bool) throws {
        if fileManager.fileExists(atPath: destination.path()) {
            try fileManager.removeItem(at: destination)
        }

        if copy {
            try fileManager.copyItem(at: source, to: destination)
        } else {
            try fileManager.moveItem(at: source, to: destination)
        }
    }
}

