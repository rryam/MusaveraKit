import Foundation
import MusaveraKit
import SwiftUI
import UniformTypeIdentifiers

struct AnalysisJSONDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    private let analysis: MusaveraAnalysis

    init(analysis: MusaveraAnalysis) {
        self.analysis = analysis
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        analysis = try JSONDecoder().decode(MusaveraAnalysis.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes
        ]
        let data = try encoder.encode(analysis)
        return FileWrapper(regularFileWithContents: data)
    }
}
