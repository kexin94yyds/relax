import SwiftUI

@main
struct RelaxationWatchExtensionApp: App {
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("-watch-session-preview") {
                NavigationStack {
                    WatchBreathingSessionView(method: BreathingMethod.all[0])
                }
            } else {
                WatchHomeView()
            }
        }
    }
}
