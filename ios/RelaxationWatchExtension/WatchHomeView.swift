import SwiftUI

struct WatchHomeView: View {
    let autoOpenMethod: BreathingMethod?

    @State private var path: [BreathingMethod] = []
    @State private var hasAutoOpened = false

    init(autoOpenMethod: BreathingMethod? = nil) {
        self.autoOpenMethod = autoOpenMethod
    }

    var body: some View {
        NavigationStack(path: $path) {
            List(BreathingMethod.all) { method in
                NavigationLink(value: method) {
                    WatchMethodRow(method: method)
                }
                .listRowBackground(WatchTheme.background)
            }
            .listStyle(.carousel)
            .scrollContentBackground(.hidden)
            .background(WatchTheme.background)
            .navigationTitle("relax")
            .navigationDestination(for: BreathingMethod.self) { method in
                WatchBreathingSessionView(method: method)
            }
            .onAppear {
                guard !hasAutoOpened, let autoOpenMethod else { return }
                hasAutoOpened = true
                path = [autoOpenMethod]
            }
        }
        .tint(WatchTheme.foreground)
        .background(WatchTheme.background)
    }
}

private struct WatchMethodRow: View {
    let method: BreathingMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(method.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(WatchTheme.foreground)
                .lineLimit(2)

            Text(BreathingExerciseMath.rhythmText(for: method))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(WatchTheme.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WatchHomeView()
}
