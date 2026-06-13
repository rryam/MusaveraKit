import Foundation
import Testing
@testable import MusaveraKit

@Suite("Musavera analysis JSON")
struct MusaveraAnalysisCodableTests {
    @Test("Encodes the native MusicUnderstanding result at the top level")
    func encodesNativeResult() throws {
        let analysis = try JSONDecoder().decode(
            MusaveraAnalysis.self,
            from: Data("{}".utf8)
        )
        let data = try JSONEncoder().encode(analysis)
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(object.isEmpty)
        #expect(analysis.instrumentActivity == nil)
        #expect(analysis.key == nil)
        #expect(analysis.loudness == nil)
        #expect(analysis.pace == nil)
        #expect(analysis.rhythm == nil)
        #expect(analysis.structure == nil)
    }
}
