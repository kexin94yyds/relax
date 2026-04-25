import SwiftUI

struct BreathingView: View {
    let method: BreathingMethod

    @Environment(\.dismiss) private var dismiss
    @State private var isActive = false
    @State private var currentPhase: BreathingPhase = .ready
    @State private var countdown = 0
    @State private var currentCycle = 0
    @State private var elapsed = 0
    @State private var soundMode: SoundMode = .gentle
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
        .onDisappear(perform: stopTimer)
        .onChange(of: soundMode) { newMode in
            feedback.exerciseModeChanged(mode: newMode, isActive: isActive)
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

                Text("第 \(currentCycle) / \(method.cycles) 轮")
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
        }
        .padding(.horizontal, 2)
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
        guard method.totalDuration > 0 else { return 0 }
        if currentPhase == .finished { return 1 }
        return min(Double(elapsed) / Double(method.totalDuration), 1)
    }

    private func startBreathing() {
        stopTimer()
        feedback.prepare()
        isActive = true
        currentCycle = 1
        elapsed = 0
        currentPhase = .inhale
        countdown = method.inhale
        feedback.exerciseStarted(mode: soundMode)
        playPhaseFeedback()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                tick()
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
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard isActive else { return }

        if countdown <= 3 && countdown > 0 {
            feedback.countdownTick(count: countdown, mode: soundMode)
        }

        guard countdown <= 1 else {
            countdown -= 1
            elapsed += 1
            return
        }

        elapsed += 1
        advancePhase()
    }

    private func advancePhase() {
        switch currentPhase {
        case .inhale:
            if method.hold > 0 {
                currentPhase = .hold
                countdown = method.hold
            } else {
                currentPhase = .exhale
                countdown = method.exhale
            }
            playPhaseFeedback()
        case .hold:
            currentPhase = .exhale
            countdown = method.exhale
            playPhaseFeedback()
        case .exhale:
            if currentCycle >= method.cycles {
                currentPhase = .finished
                isActive = false
                countdown = 0
                elapsed = method.totalDuration
                stopTimer()
                feedback.finished(mode: soundMode)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    feedback.exerciseStopped()
                }
            } else {
                currentCycle += 1
                currentPhase = .inhale
                countdown = method.inhale
                playPhaseFeedback()
            }
        case .ready, .finished:
            break
        }
    }

    private func playPhaseFeedback() {
        feedback.phaseChanged(phase: currentPhase, mode: soundMode)
    }

    private var rhythmText: String {
        if method.hold > 0 {
            return "\(method.inhale) · \(method.hold) · \(method.exhale)"
        }
        return "\(method.inhale) · \(method.exhale)"
    }
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
