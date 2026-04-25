import SwiftUI

struct BreathingView: View {
    let method: BreathingMethod

    @Environment(\.dismiss) private var dismiss
    @State private var isActive = false
    @State private var currentPhase: BreathingPhase = .ready
    @State private var countdown = 0
    @State private var currentCycle = 0
    @State private var elapsed = 0
    @State private var soundEnabled = true
    @State private var timer: Timer?

    private let feedback = FeedbackService()

    var body: some View {
        ZStack {
            method.color.opacity(0.08)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    breathingCircle
                    progressSection
                    controls
                    instructions
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onDisappear(perform: stopTimer)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Label("返回", systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)

            Spacer()

            Text(method.name)
                .font(.title3.weight(.bold))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                soundEnabled.toggle()
            } label: {
                Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderedProminent)
            .tint(soundEnabled ? method.color : .gray)
            .accessibilityLabel(soundEnabled ? "关闭声音" : "开启声音")
        }
        .padding(.top, 18)
    }

    private var breathingCircle: some View {
        ZStack {
            Circle()
                .stroke(currentDisplayColor.opacity(0.24), lineWidth: 18)
                .frame(width: 270, height: 270)
                .scaleEffect(circleScale)
                .animation(.easeInOut(duration: 1), value: currentPhase)

            Circle()
                .stroke(currentDisplayColor, lineWidth: 4)
                .frame(width: 270, height: 270)
                .scaleEffect(circleScale)
                .animation(.easeInOut(duration: 1), value: currentPhase)

            VStack(spacing: 10) {
                Text(currentPhase.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(currentDisplayColor)

                Text("\(currentPhase == .finished ? 0 : countdown)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.primary)

                Text("第 \(currentCycle) / \(method.cycles) 轮")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 340)
    }

    private var progressSection: some View {
        VStack(spacing: 10) {
            ProgressView(value: progress)
                .tint(method.color)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            Text("\(Int((progress * 100).rounded()))% 完成")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var controls: some View {
        if !isActive && currentPhase == .ready {
            Button("开始练习", action: startBreathing)
                .buttonStyle(PrimaryActionButtonStyle(color: method.color))
        } else if isActive && currentPhase != .finished {
            Button("停止练习", action: stopBreathing)
                .buttonStyle(PrimaryActionButtonStyle(color: .red))
        } else if currentPhase == .finished {
            VStack(spacing: 14) {
                Text("练习完成！")
                    .font(.title3.weight(.bold))

                Button("重新开始", action: startBreathing)
                    .buttonStyle(PrimaryActionButtonStyle(color: method.color))

                Button("返回首页") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("练习说明")
                .font(.headline)

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
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var currentDisplayColor: Color {
        currentPhase == .ready ? method.color : currentPhase.color
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
        isActive = true
        currentCycle = 1
        elapsed = 0
        currentPhase = .inhale
        countdown = method.inhale
        playPhaseFeedback()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                tick()
            }
        }
    }

    private func stopBreathing() {
        stopTimer()
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

        if countdown <= 3 && countdown > 0 && soundEnabled {
            feedback.countdownTick()
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
                if soundEnabled {
                    feedback.finished()
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
        if soundEnabled {
            feedback.phaseChanged()
        }
    }
}

private struct InstructionRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.subheadline)
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        BreathingView(method: BreathingMethod.all[0])
    }
}
