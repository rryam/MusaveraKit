import SwiftUI

@main
struct MusaveraLabApp: App {
    @State private var model = MusaveraLabModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .environment(model.previewPlayer)
                .frame(minWidth: 1_080, minHeight: 720)
        }
        .defaultSize(width: 1_320, height: 860)
    }
}
