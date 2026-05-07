import SwiftUI

struct WatchHomeView: View {
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                List(BreathingMethod.all) { method in
                    NavigationLink {
                        WatchBreathingSessionView(method: method)
                    } label: {
                        WatchMethodRow(method: method)
                    }
                    .listRowBackground(WatchTheme.background)
                }
                .listStyle(.carousel)
                .scrollContentBackground(.hidden)
                .background(WatchTheme.background)
                .padding(.top, 24)

                Text("relax")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WatchTheme.secondary)
                    .padding(.top, 18)
                    .padding(.leading, 30)
                    .accessibilityAddTraits(.isHeader)
            }
            .background(WatchTheme.background)
            .toolbar(.hidden, for: .navigationBar)
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
