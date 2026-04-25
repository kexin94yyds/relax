import SwiftUI

struct BreathingView: View {
    let method: BreathingMethod

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var isActive = false
    @State private var currentPhase: BreathingPhase = .ready
    @State private var countdown = 0
    @State private var currentCycle = 0
    @State private var elapsed = 0
    @State private var soundMode: SoundMode = .gentle
    @State private var durationIndex = 0.0
    @State private var startedAt: Date?
    @State private var timer: Timer?

    @State private var feedback = FeedbackService()

    var body: some View {
        ZStack {
            RelaxationTheme.paper
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    header
                    breathingCircle
                    progressSection
                    controls
                    instructions
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 34)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            stopTimer()
            feedback.exerciseStopped()
        }
        .onChange(of: soundMode) { newMode in
            feedback.exerciseModeChanged(mode: newMode, isActive: isActive)
            if isActive && newMode != .silent {
                updateNowPlaying()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if isActive && (newPhase == .inactive || newPhase == .background) {
                syncProgressFromClock(playFeedback: false)
                showExerciseNotification()
            } else if newPhase == .active {
                syncProgressFromClock(playFeedback: false)
                feedback.exerciseModeChanged(mode: soundMode, isActive: isActive)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RelaxationTheme.ink)
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(RelaxationTheme.hairline, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 4) {
                Text(method.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RelaxationTheme.ink)
                    .lineLimit(1)

                Text(rhythmText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(RelaxationTheme.mutedInk)
            }

            Spacer()

            Button {
                soundMode = soundMode == .silent ? .gentle : .silent
            } label: {
                Image(systemName: soundMode == .silent ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RelaxationTheme.ink)
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(RelaxationTheme.hairline, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(soundMode == .silent ? "开启声音" : "关闭声音")
        }
        .padding(.top, 18)
    }

    private var breathingCircle: some View {
        ZStack {
            Circle()
                .stroke(RelaxationTheme.hairline, lineWidth: 1)
                .frame(width: 284, height: 284)

            Circle()
                .stroke(RelaxationTheme.ink.opacity(0.1), lineWidth: 18)
                .frame(width: 248, height: 248)
                .scaleEffect(circleScale)
                .animation(.easeInOut(duration: 1), value: currentPhase)

            Circle()
                .stroke(RelaxationTheme.ink, lineWidth: 2)
                .frame(width: 248, height: 248)
                .scaleEffect(circleScale)
                .animation(.easeInOut(duration: 1), value: currentPhase)

            VStack(spacing: 12) {
                Text(currentPhase.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RelaxationTheme.ink)

                Text("\(currentPhase == .finished ? 0 : countdown)")
                    .font(.system(size: 66, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(RelaxationTheme.ink)

                Text("第 \(currentCycle) / \(plannedCycles) 轮")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(RelaxationTheme.secondaryInk)
            }
        }
        .frame(height: 348)
    }

    private var progressSection: some View {
        VStack(spacing: 14) {
            Picker("声音模式", selection: $soundMode) {
                ForEach(SoundMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(RelaxationTheme.ink)

            ProgressView(value: progress)
                .tint(RelaxationTheme.ink)
                .scaleEffect(x: 1, y: 1.2, anchor: .center)

            Text("\(Int((progress * 100).rounded()))% 完成")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(RelaxationTheme.mutedInk)
                .monospacedDigit()

            durationSelector
        }
        .padding(.horizontal, 2)
    }

    private var durationSelector: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("练习时长")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RelaxationTheme.ink)

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(selectedDurationOption.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(RelaxationTheme.ink)

                    Text("实际 \(formattedDuration(plannedTotalDuration)) · \(plannedCycles) 轮")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(RelaxationTheme.mutedInk)
                        .monospacedDigit()
                }
            }

            Slider(
                value: $durationIndex,
                in: 0...Double(PracticeDurationOption.allCases.count - 1),
                step: 1
            )
            .tint(RelaxationTheme.ink)
            .disabled(isActive || currentPhase != .ready)

            HStack(spacing: 0) {
                ForEach(PracticeDurationOption.allCases) { option in
                    Text(option.tickLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(option == selectedDurationOption ? RelaxationTheme.ink : RelaxationTheme.mutedInk)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 4)
        .opacity(isActive ? 0.55 : 1)
    }

    @ViewBuilder
    private var controls: some View {
        if !isActive && currentPhase == .ready {
            Button("开始", action: startBreathing)
                .buttonStyle(MonochromeButtonStyle(isFilled: true))
        } else if isActive && currentPhase != .finished {
            Button("停止", action: stopBreathing)
                .buttonStyle(MonochromeButtonStyle(isFilled: false))
        } else if currentPhase == .finished {
            VStack(spacing: 14) {
                Text("练习完成")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(RelaxationTheme.ink)

                Button("重新开始", action: startBreathing)
                    .buttonStyle(MonochromeButtonStyle(isFilled: true))

                Button("返回首页") {
                    dismiss()
                }
                .buttonStyle(MonochromeButtonStyle(isFilled: false))
            }
        }
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("练习说明")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RelaxationTheme.ink)

            Divider()
                .overlay(RelaxationTheme.hairline)

            if method.id == "6" {
                InstructionRow(text: "找一个安静舒适的地方坐下")
                InstructionRow(text: "保持背部挺直，肩膀放松")
                InstructionRow(text: "先进行三次深呼吸准备")
                InstructionRow(text: "跟随屏幕提示进行呼吸练习")
                InstructionRow(text: "练习完成后，从头到脚感受身体各部分")
                InstructionRow(text: "保持这种平静状态几分钟")
            } else {
                InstructionRow(text: "找一个安静舒适的地方坐下")
                InstructionRow(text: "保持背部挺直，肩膀放松")
                InstructionRow(text: "跟随屏幕提示进行呼吸")
                InstructionRow(text: "声音和震动会提醒你改变呼吸节奏")
                InstructionRow(text: "专注于你的呼吸，让思绪平静下来")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RelaxationTheme.softFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RelaxationTheme.hairline, lineWidth: 1)
        )
    }

    private var circleScale: CGFloat {
        switch currentPhase {
        case .inhale:
            return 1.12
        case .exhale:
            return 0.82
        default:
            return 1
        }
    }

    private var progress: Double {
        guard plannedTotalDuration > 0 else { return 0 }
        if currentPhase == .finished { return 1 }
        return min(Double(elapsed) / Double(plannedTotalDuration), 1)
    }

    private var selectedDurationOption: PracticeDurationOption {
        let index = min(
            max(Int(durationIndex.rounded()), 0),
            PracticeDurationOption.allCases.count - 1
        )
        return PracticeDurationOption.allCases[index]
    }

    private var plannedCycles: Int {
        guard method.cycleDuration > 0 else { return method.cycles }
        guard let targetSeconds = selectedDurationOption.targetSeconds else { return method.cycles }
        return max(1, Int((Double(targetSeconds) / Double(method.cycleDuration)).rounded()))
    }

    private var plannedTotalDuration: Int {
        method.cycleDuration * plannedCycles
    }

    private func startBreathing() {
        stopTimer()
        feedback.prepare()
        feedback.requestNotificationPermission()
        isActive = true
        startedAt = Date()
        currentCycle = 1
        elapsed = 0
        currentPhase = .inhale
        countdown = method.inhale
        feedback.exerciseStarted(mode: soundMode)
        playPhaseFeedback()
        updateNowPlaying()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                syncProgressFromClock(playFeedback: true)
            }
        }
    }

    private func stopBreathing() {
        stopTimer()
        feedback.exerciseStopped()
        isActive = false
        currentPhase = .ready
        countdown = 0
        currentCycle = 0
        elapsed = 0
        startedAt = nil
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func syncProgressFromClock(playFeedback: Bool) {
        guard isActive, let startedAt else { return }

        let realElapsed = min(max(Int(Date().timeIntervalSince(startedAt)), 0), plannedTotalDuration)
        let previousPhase = currentPhase
        let previousCycle = currentCycle
        let snapshot = exerciseSnapshot(for: realElapsed)

        if snapshot.isFinished {
            finishBreathing()
            return
        }

        currentPhase = snapshot.phase
        countdown = snapshot.countdown
        currentCycle = snapshot.cycle
        elapsed = snapshot.elapsed

        if countdown <= 3 && countdown > 0 {
            feedback.countdownTick(count: countdown, mode: soundMode)
        }

        if playFeedback && (currentPhase != previousPhase || currentCycle != previousCycle) {
            playPhaseFeedback()
        }

        updateNowPlaying()
    }

    private func exerciseSnapshot(for realElapsed: Int) -> ExerciseSnapshot {
        guard method.cycleDuration > 0, realElapsed < plannedTotalDuration else {
            return ExerciseSnapshot(
                phase: .finished,
                countdown: 0,
                cycle: plannedCycles,
                elapsed: plannedTotalDuration,
                isFinished: true
            )
        }

        let cycleIndex = realElapsed / method.cycleDuration
        let cycleElapsed = realElapsed % method.cycleDuration
        let cycle = min(cycleIndex + 1, plannedCycles)

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

    private func finishBreathing() {
        currentPhase = .finished
        isActive = false
        countdown = 0
        elapsed = plannedTotalDuration
        startedAt = nil
        stopTimer()
        feedback.finished(mode: soundMode)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            feedback.exerciseStopped()
        }
    }

    private func playPhaseFeedback() {
        feedback.phaseChanged(phase: currentPhase, mode: soundMode)
    }

    private func updateNowPlaying() {
        guard soundMode != .silent else { return }

        feedback.updateNowPlaying(
            methodName: method.name,
            phase: currentPhase,
            cycle: currentCycle,
            totalCycles: plannedCycles,
            elapsed: elapsed,
            totalDuration: plannedTotalDuration,
            isActive: isActive
        )
    }

    private func showExerciseNotification() {
        feedback.showExerciseNotification(
            methodName: method.name,
            phase: currentPhase,
            cycle: currentCycle,
            totalCycles: plannedCycles
        )
    }

    private func formattedDuration(_ seconds: Int) -> String {
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

    private var rhythmText: String {
        if method.hold > 0 {
            return "\(method.inhale) · \(method.hold) · \(method.exhale)"
        }
        return "\(method.inhale) · \(method.exhale)"
    }
}

private enum PracticeDurationOption: Int, CaseIterable, Identifiable {
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

    var title: String {
        switch self {
        case .defaultPlan:
            return "默认"
        case .threeMinutes:
            return "约 3 分钟"
        case .fiveMinutes:
            return "约 5 分钟"
        case .tenMinutes:
            return "约 10 分钟"
        case .fifteenMinutes:
            return "约 15 分钟"
        case .twentyMinutes:
            return "约 20 分钟"
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

private struct ExerciseSnapshot {
    let phase: BreathingPhase
    let countdown: Int
    let cycle: Int
    let elapsed: Int
    let isFinished: Bool
}

private struct InstructionRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(RelaxationTheme.ink)
                .frame(width: 5, height: 1)
                .padding(.top, 10)

            Text(text)
                .foregroundStyle(RelaxationTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 14))
    }
}

private struct MonochromeButtonStyle: ButtonStyle {
    let isFilled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(isFilled ? RelaxationTheme.paper : RelaxationTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                (isFilled ? RelaxationTheme.ink : Color.clear)
                    .opacity(configuration.isPressed ? 0.78 : 1),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(RelaxationTheme.ink, lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        BreathingView(method: BreathingMethod.all[0])
    }
}
