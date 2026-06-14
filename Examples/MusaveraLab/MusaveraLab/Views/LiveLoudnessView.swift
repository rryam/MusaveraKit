import Charts
import CoreMedia
import MusicUnderstanding
import SwiftUI

struct LiveLoudnessView: View {
    @Environment(LiveStreamModel.self) private var model

    private let metricColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        AnalysisTile(title: "Realtime Loudness", systemImage: "waveform") {
            VStack(alignment: .leading, spacing: 18) {
                LazyVGrid(columns: metricColumns, spacing: 10) {
                    LiveLoudnessMetric(
                        title: "Momentary",
                        value: formatted(model.latestMomentaryValue),
                        unit: "LUFS"
                    )

                    LiveLoudnessMetric(
                        title: "Short-Term",
                        value: formatted(model.latestShortTermValue),
                        unit: "LUFS"
                    )

                    LiveLoudnessMetric(
                        title: "Integrated",
                        value: formatted(model.integratedValue),
                        unit: "LUFS"
                    )

                    LiveLoudnessMetric(
                        title: "Peak",
                        value: formatted(model.peakValue),
                        unit: "dB"
                    )
                }

                if model.momentaryHistory.isEmpty {
                    ContentUnavailableView {
                        Label("Waiting for Audio", systemImage: "waveform")
                    } description: {
                        Text("Start listening and play music or speak near the selected microphone.")
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    LiveLoudnessChart(
                        values: model.momentaryHistory,
                        elapsedTime: model.elapsedTime
                    )
                    .frame(height: 250)
                }
            }
        }
    }

    private func formatted(_ value: Float?) -> String {
        value.map { String(format: "%.1f", $0) } ?? "--"
    }
}

private struct LiveLoudnessMetric: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()

                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.65), in: RoundedRectangle(cornerRadius: 11))
        .accessibilityElement(children: .combine)
    }
}

private struct LiveLoudnessChart: View {
    let values: [MusicUnderstandingSession.TimedValue<Float>]
    let elapsedTime: TimeInterval

    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { _, point in
            AreaMark(
                x: .value("Time", point.time.seconds),
                yStart: .value("Floor", -72),
                yEnd: .value("Loudness", point.value)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [
                        LabTheme.loudness.opacity(0.3),
                        LabTheme.loudness.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Time", point.time.seconds),
                y: .value("Loudness", point.value)
            )
            .foregroundStyle(LabTheme.loudness)
            .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round))
            .interpolationMethod(.linear)
        }
        .chartXScale(domain: visibleDomain)
        .chartYScale(domain: -72...0)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine()
                    .foregroundStyle(.secondary.opacity(0.12))
                AxisValueLabel {
                    if let seconds = value.as(Double.self) {
                        Text("\(Int(seconds))s")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [-72, -60, -48, -36, -24, -12, 0]) {
                value in
                AxisGridLine()
                    .foregroundStyle(.secondary.opacity(0.14))
                AxisValueLabel {
                    if let loudness = value.as(Int.self) {
                        Text("\(loudness)")
                    }
                }
            }
        }
        .accessibilityLabel("Live momentary loudness")
        .accessibilityValue(
            values.last.map { String(format: "%.1f LUFS", $0.value) }
            ?? "No loudness values"
        )
    }

    private var visibleDomain: ClosedRange<Double> {
        let latestTime = max(
            elapsedTime,
            values.last?.time.seconds ?? 0
        )
        let upperBound = max(latestTime, 10)
        return max(upperBound - 30, 0)...upperBound
    }
}
