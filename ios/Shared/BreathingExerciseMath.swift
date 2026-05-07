import SwiftUI

struct PracticePlan: Equatable {
    let targetSeconds: Int
    let cycles: Int
    let totalDuration: Int
}

enum PracticeDurationOption: Int, CaseIterable, Identifiable {
    case defaultPlan
    case threeMinutes
    case fiveMinutes
    case tenMinutes
    case fifteenMinutes
    case twentyMinutes

    var id: Int { rawValue }

    var targetSeconds: Int? {
        switch self {
        case .defaultPlan:
            return nil
        case .threeMinutes:
            return 3 * 60
        case .fiveMinutes:
            return 5 * 60
        case .tenMinutes:
            return 10 * 60
        case .fifteenMinutes:
            return 15 * 60
        case .twentyMinutes:
            return 20 * 60
        }
    }

    var tickLabel: String {
        switch self {
        case .defaultPlan:
            return "默认"
        case .threeMinutes:
            return "3"
        case .fiveMinutes:
            return "5"
        case .tenMinutes:
            return "10"
        case .fifteenMinutes:
            return "15"
        case .twentyMinutes:
            return "20"
        }
    }
}

struct ExerciseSnapshot: Equatable {
    let phase: BreathingPhase
    let countdown: Int
    let cycle: Int
    let elapsed: Int
    let isFinished: Bool
}

enum BreathingExerciseMath {
    static func targetSeconds(for option: PracticeDurationOption, fallback fallbackSeconds: Int) -> Int {
        option.targetSeconds ?? fallbackSeconds
    }

    static func plan(for method: BreathingMethod, targetSeconds: Int) -> PracticePlan {
        guard method.cycleDuration > 0 else {
            return PracticePlan(targetSeconds: targetSeconds, cycles: method.cycles, totalDuration: method.totalDuration)
        }

        let cycles = max(1, Int((Double(targetSeconds) / Double(method.cycleDuration)).rounded()))
        return PracticePlan(
            targetSeconds: targetSeconds,
            cycles: cycles,
            totalDuration: method.cycleDuration * cycles
        )
    }

    static func snapshot(for realElapsed: Int, method: BreathingMethod, totalCycles: Int, totalDuration: Int) -> ExerciseSnapshot {
        guard method.cycleDuration > 0, realElapsed < totalDuration else {
            return ExerciseSnapshot(
                phase: .finished,
                countdown: 0,
                cycle: totalCycles,
                elapsed: totalDuration,
                isFinished: true
            )
        }

        let cycleIndex = realElapsed / method.cycleDuration
        let cycleElapsed = realElapsed % method.cycleDuration
        let cycle = min(cycleIndex + 1, totalCycles)

        if cycleElapsed < method.inhale {
            return ExerciseSnapshot(
                phase: .inhale,
                countdown: method.inhale - cycleElapsed,
                cycle: cycle,
                elapsed: realElapsed,
                isFinished: false
            )
        }

        let holdEnd = method.inhale + method.hold
        if method.hold > 0 && cycleElapsed < holdEnd {
            return ExerciseSnapshot(
                phase: .hold,
                countdown: holdEnd - cycleElapsed,
                cycle: cycle,
                elapsed: realElapsed,
                isFinished: false
            )
        }

        let exhaleElapsed = cycleElapsed - holdEnd
        return ExerciseSnapshot(
            phase: .exhale,
            countdown: max(method.exhale - exhaleElapsed, 1),
            cycle: cycle,
            elapsed: realElapsed,
            isFinished: false
        )
    }

    static func progress(elapsed: Int, totalDuration: Int, currentPhase: BreathingPhase) -> Double {
        guard totalDuration > 0 else { return 0 }
        if currentPhase == .finished { return 1 }
        return min(Double(elapsed) / Double(totalDuration), 1)
    }

    static func formattedDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60

        if minutes == 0 {
            return "\(remainder)秒"
        }

        if remainder == 0 {
            return "\(minutes)分钟"
        }

        return "\(minutes)分\(remainder)秒"
    }

    static func rhythmText(for method: BreathingMethod) -> String {
        if method.hold > 0 {
            return "\(method.inhale) · \(method.hold) · \(method.exhale)"
        }
        return "\(method.inhale) · \(method.exhale)"
    }

    static func circleScale(for phase: BreathingPhase) -> CGFloat {
        switch phase {
        case .inhale:
            return 1.12
        case .exhale:
            return 0.82
        default:
            return 1
        }
    }
}
