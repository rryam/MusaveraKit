import MusicUnderstanding
import Testing
@testable import MusaveraKit

@Suite("Musavera analysis options")
struct MusaveraAnalysisOptionsTests {
    @Test("Maps all focused options to MusicUnderstanding analysis types")
    func mapsFocusedOptions() {
        #expect(MusaveraAnalysisOptions.rhythm.musicUnderstandingTypes == [.rhythm])
        #expect(MusaveraAnalysisOptions.key.musicUnderstandingTypes == [.key])
        #expect(MusaveraAnalysisOptions.loudness.musicUnderstandingTypes == [.loudness])
        #expect(MusaveraAnalysisOptions.pace.musicUnderstandingTypes == [.pace])
        #expect(MusaveraAnalysisOptions.structure.musicUnderstandingTypes == [.structure])
        #expect(MusaveraAnalysisOptions.instrumentActivity.musicUnderstandingTypes == [.instrumentActivity])
    }

    @Test("All contains six analysis types")
    func allContainsEveryAnalysisType() {
        #expect(MusaveraAnalysisOptions.all.musicUnderstandingTypes == [
            .instrumentActivity,
            .key,
            .loudness,
            .pace,
            .rhythm,
            .structure
        ])
    }
}
