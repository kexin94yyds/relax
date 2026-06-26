import SwiftUI

@main
struct RelaxationMacApp: App {
    @StateObject private var session = MacBreathingSessionModel()

    var body: some Scene {
        MenuBarExtra {
            MacMenuBarView(session: session)
        } label: {
            Label("relax", systemImage: session.isActive ? "leaf.fill" : "leaf")
        }
        .menuBarExtraStyle(.window)

        Window("呼吸", id: MacWindowID.breathingSession) {
            MacBreathingSessionView(session: session)
                .frame(width: 420, height: 540)
                .background(RelaxationTheme.paper)
        }
        .defaultSize(width: 420, height: 540)
        .windowResizability(.contentSize)
    }
}

enum MacWindowID {
    static let breathingSession = "breathing-session"
}
