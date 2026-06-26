import Combine
import Foundation

enum MacPracticeDuration: Int, CaseIterable, Identifiable {
    case oneMinute = 60
    case threeMinutes = 180
    case fiveMinutes = 300

    var id: Int { rawValue }
    var seconds: Int { rawValue }

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

    var shortTitle: String {
        switch self {
        case .oneMinute:
            return "1"
        case .threeMinutes:
            return "3"
        case .fiveMinutes:
            return "5"
        }
    }
}

@MainActor
final class MacBreathingSessionModel: ObservableObject {
    @Published var method: BreathingMethod = BreathingMethod.all[0]
    @Published var duration: MacPracticeDuration = .threeMinutes
    @Published private(set) var currentPhase: BreathingPhase = .ready
    @Published private(set) var countdown = 0
    @Published private(set) var currentCycle = 0
    @Published private(set) var elapsed = 0
    @Published private(set) var isActive = false

    private var startedAt: Date?
    private var timer: Timer?

    var plan: PracticePlan {
        BreathingExerciseMath.plan(for: method, targetSeconds: duration.seconds)
    }

    var progress: Double {
        BreathingExerciseMath.progress(
            elapsed: elapsed,
            totalDuration: plan.totalDuration,
            currentPhase: currentPhase
        )
    }

    var remainingSeconds: Int {
        max(plan.totalDuration - elapsed, 0)
    }

    var statusTitle: String {
        if currentPhase == .ready {
            return "准备开始"
        }

        if currentPhase == .finished {
            return "练习完成"
        }

        return "\(currentPhase.title) · 第 \(max(currentCycle, 1)) / \(plan.cycles) 轮"
    }

    var remainingText: String {
        BreathingExerciseMath.formattedDuration(remainingSeconds)
    }

    func prepare(method: BreathingMethod, duration: MacPracticeDuration) {
        guard !isActive else { return }
        self.method = method
        self.duration = duration
    }

    func start(method: BreathingMethod? = nil, duration: MacPracticeDuration? = nil) {
        stopTimer()

        if let method {
            self.method = method
        }

        if let duration {
            self.duration = duration
        }

        isActive = true
        startedAt = Date()
        currentPhase = .inhale
        countdown = self.method.inhale
        currentCycle = 1
        elapsed = 0
        scheduleTimer()
    }

    func stop() {
        stopTimer()
        isActive = false
        startedAt = nil
        currentPhase = .ready
        countdown = 0
        currentCycle = 0
        elapsed = 0
    }

    func restart() {
        start(method: method, duration: duration)
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncProgressFromClock()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func syncProgressFromClock() {
        guard isActive, let startedAt else { return }

        let realElapsed = min(max(Int(Date().timeIntervalSince(startedAt)), 0), plan.totalDuration)
        let snapshot = BreathingExerciseMath.snapshot(
            for: realElapsed,
            method: method,
            totalCycles: plan.cycles,
            totalDuration: plan.totalDuration
        )

        if snapshot.isFinished {
            finish()
            return
        }

        currentPhase = snapshot.phase
        countdown = snapshot.countdown
        currentCycle = snapshot.cycle
        elapsed = snapshot.elapsed
    }

    private func finish() {
        stopTimer()
        isActive = false
        startedAt = nil
        currentPhase = .finished
        countdown = 0
        currentCycle = plan.cycles
        elapsed = plan.totalDuration
    }
}
