import MusaveraKit
import SwiftUI

struct LiveFinalAnalysisView: View {
    @Environment(LiveStreamModel.self) private var model

    let analysis: MusaveraAnalysis
    let onExport: () -> Void

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

            AnalysisResultsView(analysis: analysis)
                .environment(model.recordingPlayer)
        }
        .padding(.top, 4)
    }
}
