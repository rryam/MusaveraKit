import MusaveraKit
import SwiftUI

struct AnalysisResultsView: View {
    let analysis: MusaveraAnalysis

    private let summaryColumns = [
        GridItem(.adaptive(minimum: 280), spacing: 12)
    ]

    private let activityColumns = [
        GridItem(.adaptive(minimum: 330, maximum: 660), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: summaryColumns, spacing: 12) {
                AnalysisTile(title: "Key", systemImage: "music.quarternote.3") {
                    KeySummaryView(key: analysis.key)
                }

                AnalysisTile(title: "Rhythm", systemImage: "metronome") {
                    RhythmSummaryView(rhythm: analysis.rhythm)
                }
            }

            if let structure = analysis.structure {
                AnalysisTile(title: "Structure", systemImage: "square.3.layers.3d") {
                    StructureTimeline(result: structure)
                        .frame(height: 88)
                        .playheadOverlay()
                }
            }

            if let pace = analysis.pace {
                AnalysisTile(title: "Pace", systemImage: "speedometer") {
                    PaceChart(result: pace)
                        .frame(height: 150)
                        .playheadOverlay()
                }
            }

            if let instruments = analysis.instrumentActivity {
                AnalysisTile(title: "Instrument Ranges", systemImage: "pianokeys") {
                    InstrumentRangesChart(result: instruments)
                        .frame(height: 190)
                        .playheadOverlay()
                }

                LazyVGrid(columns: activityColumns, spacing: 12) {
                    ForEach(
                        InstrumentActivityResult.Instrument.labOrder,
                        id: \.rawValue
                    ) { instrument in
                        AnalysisTile(
                            title: "\(instrument.rawValue.capitalized) Activity",
                            systemImage: instrument.systemImage
                        ) {
                            InstrumentActivityChart(
                                values: instruments.activity(for: instrument),
                                color: instrument.labColor
                            )
                            .frame(height: 110)
                            .playheadOverlay()
                        }
                    }
                }
            }

            if let loudness = analysis.loudness {
                AnalysisTile(title: "Loudness", systemImage: "waveform") {
                    LoudnessAnalysisView(result: loudness)
                }
            }
        }
    }
}
