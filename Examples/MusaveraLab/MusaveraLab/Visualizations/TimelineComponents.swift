import Charts
import CoreMedia
import MusicUnderstanding
import SwiftUI

private struct PlayheadOverlay: View {
    @Environment(PreviewPlayer.self) private var player
    @State private var width: CGFloat = 0

    var body: some View {
        ZStack(alignment: .leading) {
            TimelineView(.animation(paused: !player.isPlaying)) { _ in
                let progress = player.duration > 0
                    ? min(max(player.currentTime / player.duration, 0), 1)
                    : 0

                Rectangle()
                    .fill(LabTheme.playhead)
                    .frame(width: 2)
                    .offset(x: width * progress)
            }

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    guard width > 0 else { return }
                    player.seek(to: (location.x / width) * player.duration)
                }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            width = newWidth
        }
    }
}

extension View {
    func playheadOverlay() -> some View {
        overlay {
            PlayheadOverlay()
        }
    }
}

struct StructureTimeline: View {
    let result: StructureResult

    var body: some View {
        VStack(spacing: 8) {
            StructureBar(ranges: result.sections, color: LabTheme.structure)
                .frame(height: 22)

            StructureBar(ranges: result.segments, color: LabTheme.segment)
                .frame(height: 16)

            StructureBar(ranges: result.phrases, color: LabTheme.phrase)
                .frame(height: 11)
        }
        .accessibilityLabel(
            "\(result.sections.count) sections, \(result.segments.count) segments, and \(result.phrases.count) phrases"
        )
    }
}

private struct StructureBar: View {
    @Environment(PreviewPlayer.self) private var player
    @State private var size: CGSize = .zero

    let ranges: [CMTimeRange]
    let color: Color

    var body: some View {
        Color.clear
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                size = newSize
            }
            .overlay(alignment: .leading) {
                if player.duration > 0 {
                    ForEach(Array(ranges.enumerated()), id: \.offset) { _, range in
                        let start = max(range.start.seconds, 0)
                        let end = min(CMTimeRangeGetEnd(range).seconds, player.duration)
                        let width = max(((end - start) / player.duration) * size.width - 2, 1)
                        let offset = (start / player.duration) * size.width
                        let isActive = player.currentTime >= start && player.currentTime < end

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(color.opacity(isActive && player.isPlaying ? 0.9 : 0.4))
                            .frame(width: width, height: size.height)
                            .offset(x: offset)
                    }
                }
            }
    }
}

struct PaceChart: View {
    @Environment(PreviewPlayer.self) private var player

    let result: PaceResult

    var body: some View {
        let maximum = max(result.ranges.map(\.value).max() ?? 1, 1)

        Chart(Array(result.ranges.enumerated()), id: \.offset) { _, rangedValue in
            BarMark(
                xStart: .value("Start", rangedValue.range.start.seconds),
                xEnd: .value("End", CMTimeRangeGetEnd(rangedValue.range).seconds),
                y: .value("Pace", rangedValue.value)
            )
            .foregroundStyle(LabTheme.pace.gradient)
            .cornerRadius(5)
        }
        .chartXScale(domain: 0...max(player.duration, 1))
        .chartYScale(domain: 0...maximum)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct InstrumentRangesChart: View {
    @Environment(PreviewPlayer.self) private var player

    let result: InstrumentActivityResult

    var body: some View {
        Chart {
            ForEach(InstrumentActivityResult.Instrument.labOrder, id: \.rawValue) { instrument in
                ForEach(result.ranges[instrument] ?? [], id: \.self) { range in
                    BarMark(
                        xStart: .value("Start", range.start.seconds),
                        xEnd: .value("End", CMTimeRangeGetEnd(range).seconds),
                        y: .value("Instrument", instrument.rawValue.capitalized)
                    )
                    .foregroundStyle(instrument.labColor.gradient)
                    .cornerRadius(5)
                }
            }
        }
        .chartXScale(domain: 0...max(player.duration, 1))
        .chartXAxis(.hidden)
    }
}

struct InstrumentActivityChart: View {
    let values: [MusicUnderstandingSession.TimedValue<Float>]
    let color: Color

    var body: some View {
        TimeSeriesChart(
            values: values,
            color: color,
            yDomain: 0...1
        )
    }
}

struct LoudnessAnalysisView: View {
    let result: LoudnessResult

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 28) {
                LoudnessMetric(
                    label: "Peak",
                    value: String(format: "%.1f dB", result.peak.value)
                )

                LoudnessMetric(
                    label: "Integrated",
                    value: String(format: "%.1f LUFS", result.integrated.value)
                )

                Spacer()
            }

            TimeSeriesChart(
                values: result.momentary,
                color: LabTheme.loudness,
                yDomain: -60...0
            )
            .frame(height: 180)
            .playheadOverlay()
        }
    }
}

private struct LoudnessMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold().monospacedDigit())
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TimeSeriesChart: View {
    @Environment(PreviewPlayer.self) private var player

    let values: [MusicUnderstandingSession.TimedValue<Float>]
    let color: Color
    let yDomain: ClosedRange<Double>

    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { _, point in
            LineMark(
                x: .value("Time", point.time.seconds),
                y: .value("Value", point.value)
            )
            .foregroundStyle(color)
            .interpolationMethod(.linear)
        }
        .chartXScale(domain: 0...max(player.duration, 1))
        .chartYScale(domain: yDomain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

extension InstrumentActivityResult.Instrument {
    static let labOrder: [Self] = [.vocal, .drum, .bass, .other]

    var labColor: Color {
        switch self {
        case .vocal:
            LabTheme.accent
        case .drum:
            LabTheme.accent.opacity(0.78)
        case .bass:
            LabTheme.accent.opacity(0.58)
        case .other:
            LabTheme.accent.opacity(0.38)
        default:
            LabTheme.accent.opacity(0.38)
        }
    }

    var systemImage: String {
        switch self {
        case .vocal:
            "mic.fill"
        case .drum:
            "circle.grid.cross.fill"
        case .bass:
            "guitars.fill"
        case .other:
            "waveform"
        default:
            "music.note"
        }
    }
}
