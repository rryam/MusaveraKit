import Testing
@testable import MusaveraKit

@Suite("MusaveraKit errors")
struct MusaveraKitErrorTests {
    @Test("Empty analysis error has an actionable description")
    func emptyAnalysisDescription() {
        let error = MusaveraKitError.emptyAnalysisSet

        #expect(error.description == "At least one analysis option is required.")
        #expect(error.errorDescription == error.description)
    }

    @Test("Missing result error identifies the requested result")
    func missingResultDescription() {
        let error = MusaveraKitError.missingResult("rhythm")

        #expect(error.description == "MusicUnderstanding did not return a rhythm result.")
        #expect(error.errorDescription == error.description)
    }
}
