import SwiftUI
import SwiftData

@main
struct TrackProteinApp: App {
    /// App-Group-backed container shared with the widget extension.
    private let container = SharedStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
