import SwiftUI
import WatchKit

struct WatchBreathingSessionView: View {
    let method: BreathingMethod

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var durationOption: WatchDurationOption = .threeMinutes
    @State private var currentPhase: BreathingPhase = .ready
    @State private var countdown = 0
    @State private var currentCycle = 0
    @State private var elapsed = 0
    @State private var isActive = false
    @State private var startedAt: Date?
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            WatchTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 4)
                header
                Spacer(minLength: 8)
                breathingCircle
                Spacer(minLength: 8)
                status
                Spacer(minLength: 10)
                controls
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stopTimer()
        }
        .onChange(of: scenePhase) { newPhase in
            if isActive && (newPhase == .active || newPhase == .inactive || newPhase == .background) {
                syncProgressFromClock(playHaptics: false)
            }
        }
    }

    private var plan: PracticePlan {
        BreathingExerciseMath.plan(for: method, targetSeconds: durationOption.seconds)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WatchTheme.foreground)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(WatchTheme.softFill)
                    )
                    .overlay(
                        Circle()
                            .stroke(WatchTheme.hairline, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(height: 34)
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text(method.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WatchTheme.foreground)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(BreathingExerciseMath.rhythmText(for: method))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(WatchTheme.secondary)
                .monospacedDigit()
        }
    }

    private var breathingCircle: some View {
        ZStack {
            Circle()
                .stroke(WatchTheme.hairline, lineWidth: 1)
                .frame(width: 108, height: 108)

            Circle()
                .stroke(WatchTheme.foreground.opacity(0.14), lineWidth: 12)
                .frame(width: 90, height: 90)
                .scaleEffect(BreathingExerciseMath.circleScale(for: currentPhase))
                .animation(.easeInOut(duration: 1), value: currentPhase)

            Circle()
                .stroke(WatchTheme.foreground, lineWidth: 1.5)
                .frame(width: 90, height: 90)
                .scaleEffect(BreathingExerciseMath.circleScale(for: currentPhase))
                .animation(.easeInOut(duration: 1), value: currentPhase)

            VStack(spacing: 2) {
                Text(currentPhase.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WatchTheme.foreground)

                Text("\(currentPhase == .finished ? 0 : countdown)")
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(WatchTheme.foreground)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 116)
    }

    private var status: some View {
        VStack(spacing: 8) {
            Text(currentPhase == .ready ? durationOption.title : "第 \(max(currentCycle, 1)) / \(plan.cycles) 轮")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WatchTheme.secondary)
                .monospacedDigit()

            ProgressView(value: BreathingExerciseMath.progress(elapsed: elapsed, totalDuration: plan.totalDuration, currentPhase: currentPhase))
                .tint(WatchTheme.foreground)
                .scaleEffect(x: 1, y: 1.15, anchor: .center)

            if !isActive && currentPhase == .ready {
                Button(durationOption.title) {
                    durationOption = durationOption.next
                }
                .buttonStyle(WatchSecondaryButtonStyle())
            } else {
                Text(BreathingExerciseMath.formattedDuration(plan.totalDuration))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(WatchTheme.muted)
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if !isActive && currentPhase == .ready {
            Button("开始", action: startSession)
                .buttonStyle(WatchPrimaryButtonStyle())
        } else if isActive && currentPhase != .finished {
            Button("结束", action: stopSession)
                .buttonStyle(WatchSecondaryButtonStyle())
        } else {
            VStack(spacing: 8) {
                Button("再来一次", action: startSession)
                    .buttonStyle(WatchPrimaryButtonStyle())

                Button("返回") {
                    dismiss()
                }
                .buttonStyle(WatchSecondaryButtonStyle())
            }
        }
    }

    private func startSession() {
        stopTimer()
        isActive = true
        startedAt = Date()
        currentCycle = 1
        elapsed = 0
        currentPhase = .inhale
        countdown = method.inhale
        playHaptic(for: .start)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                syncProgressFromClock(playHaptics: true)
            }
        }
    }

    private func stopSession() {
        stopTimer()
        isActive = false
        currentPhase = .ready
        countdown = 0
        currentCycle = 0
        elapsed = 0
        startedAt = nil
        playHaptic(for: .stop)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func syncProgressFromClock(playHaptics: Bool) {
        guard isActive, let startedAt else { return }

        let realElapsed = min(max(Int(Date().timeIntervalSince(startedAt)), 0), plan.totalDuration)
        let previousPhase = currentPhase
        let previousCycle = currentCycle
        let snapshot = BreathingExerciseMath.snapshot(
            for: realElapsed,
            method: method,
            totalCycles: plan.cycles,
            totalDuration: plan.totalDuration
        )

        if snapshot.isFinished {
            finishSession()
            return
        }

        currentPhase = snapshot.phase
        countdown = snapshot.countdown
        currentCycle = snapshot.cycle
        elapsed = snapshot.elapsed

        if playHaptics && (currentPhase != previousPhase || currentCycle != previousCycle) {
            playPhaseHaptic()
        }
    }

    private func finishSession() {
        currentPhase = .finished
        isActive = false
        countdown = 0
        elapsed = plan.totalDuration
        startedAt = nil
        stopTimer()
        playHaptic(for: .success)
    }

    private func playPhaseHaptic() {
        switch currentPhase {
        case .inhale:
            playHaptic(for: .directionUp)
        case .hold:
            playHaptic(for: .click)
        case .exhale:
            playHaptic(for: .directionDown)
        case .finished:
            playHaptic(for: .success)
        case .ready:
            break
        }
    }

    private func playHaptic(for type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
}

private enum WatchDurationOption: CaseIterable, Identifiable {
    case oneMinute
    case threeMinutes
    case fiveMinutes

    var id: String { title }

    var seconds: Int {
        switch self {
        case .oneMinute:
            return 60
        case .threeMinutes:
            return 3 * 60
        case .fiveMinutes:
            return 5 * 60
        }
    }

    var title: String {
        switch self {
        case .oneMinute:
            return "1 分钟"
        case .threeMinutes:
            return "3 分钟"
        case .fiveMinutes:
            return "5 分钟"
        }
    }

    var next: WatchDurationOption {
        switch self {
        case .oneMinute:
            return .threeMinutes
        case .threeMinutes:
            return .fiveMinutes
        case .fiveMinutes:
            return .oneMinute
        }
    }
}

private struct WatchPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(WatchTheme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                WatchTheme.foreground.opacity(configuration.isPressed ? 0.78 : 1),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
    }
}

private struct WatchSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(WatchTheme.foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                WatchTheme.softFill.opacity(configuration.isPressed ? 0.72 : 1),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(WatchTheme.hairline, lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        WatchBreathingSessionView(method: BreathingMethod.all[0])
    }
}
