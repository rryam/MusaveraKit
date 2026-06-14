import MusicUnderstanding
import MusaveraKit
import SwiftUI

struct LiveFinalAnalysisView: View {
    let analysis: MusaveraAnalysis
    let onExport: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Completed Musical Analysis")
                        .font(.title2.bold())

                    Text("These results become available after the incoming audio stream closes.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Export JSON", systemImage: "square.and.arrow.up", action: onExport)
                    .buttonStyle(.bordered)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                AnalysisTile(title: "Key", systemImage: "music.quarternote.3") {
                    KeySummaryView(key: analysis.key)
                }

                AnalysisTile(title: "Rhythm", systemImage: "metronome") {
                    RhythmSummaryView(rhythm: analysis.rhythm)
                }

                AnalysisTile(title: "Structure", systemImage: "square.3.layers.3d") {
                    HStack(spacing: 12) {
                        FinalAnalysisMetric(
                            value: analysis.sectionCount.formatted(),
                            label: "Sections"
                        )
                        FinalAnalysisMetric(
                            value: analysis.phraseCount.formatted(),
                            label: "Phrases"
                        )
                        FinalAnalysisMetric(
                            value: analysis.segmentCount.formatted(),
                            label: "Segments"
                        )
                    }
                    .frame(height: 92)
                }

                AnalysisTile(title: "Timeline", systemImage: "point.3.connected.trianglepath.dotted") {
                    HStack(spacing: 12) {
                        FinalAnalysisMetric(
                            value: analysis.beatCount.formatted(),
                            label: "Beats"
                        )
                        FinalAnalysisMetric(
                            value: analysis.barCount.formatted(),
                            label: "Bars"
                        )
                        FinalAnalysisMetric(
                            value: detectedInstruments.count.formatted(),
                            label: "Instruments"
                        )
                    }
                    .frame(height: 92)
                }
            }

            if !detectedInstruments.isEmpty {
                HStack(spacing: 8) {
                    Text("Detected")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(detectedInstruments, id: \.rawValue) { instrument in
                        Label(
                            instrument.rawValue.capitalized,
                            systemImage: instrument.systemImage
                        )
                        .font(.callout.weight(.medium))
                        .foregroundStyle(instrument.labColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(instrument.labColor.opacity(0.1), in: Capsule())
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private var detectedInstruments: [InstrumentActivityResult.Instrument] {
        guard let activity = analysis.instrumentActivity else { return [] }

        return InstrumentActivityResult.Instrument.labOrder.filter { instrument in
            !(activity.ranges[instrument] ?? []).isEmpty
                || !activity.activity(for: instrument).isEmpty
        }
    }
}

private struct FinalAnalysisMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .monospacedDigit()

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
