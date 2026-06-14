import SwiftUI

@main
struct MusaveraLabApp: App {
    @State private var model = MusaveraLabModel()
    @State private var liveStreamModel = LiveStreamModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .environment(liveStreamModel)
                .environment(model.previewPlayer)
                .tint(LabTheme.accent)
                .frame(minWidth: 1_080, minHeight: 720)
        }
        .defaultSize(width: 1_320, height: 860)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
    }
}
