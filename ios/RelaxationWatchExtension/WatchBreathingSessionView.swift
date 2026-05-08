import AVFoundation
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
    @State private var activeFeedbackPlayers: [AVAudioPlayer] = []
    @State private var audioPrepared = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            WatchTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 4)
                breathingCircle
                Spacer(minLength: 4)
                status
                Spacer(minLength: 6)
                controls
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 8)

            backButton
                .padding(.top, 8)
                .padding(.leading, 8)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stopTimer()
            releaseAudio()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if isActive && (newPhase == .active || newPhase == .inactive || newPhase == .background) {
                syncProgressFromClock(playHaptics: false)
            }
        }
    }

    private var durationDragControl: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let thumbDiameter: CGFloat = 14
            let thumbOffset = durationSelectionProgress * max(width - thumbDiameter, 0)
            let fillWidth = max(thumbDiameter, thumbOffset + thumbDiameter)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(WatchTheme.softFill)
                    .frame(height: 6)

                Capsule()
                    .fill(WatchTheme.foreground.opacity(0.9))
                    .frame(width: min(fillWidth, width), height: 6)

                Circle()
                    .fill(WatchTheme.foreground)
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .offset(x: thumbOffset)
            }
            .frame(height: 18)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateDurationOption(locationX: value.location.x, width: width, thumbDiameter: thumbDiameter)
                    }
            )
        }
        .frame(height: 18)
    }

    private var plan: PracticePlan {
        BreathingExerciseMath.plan(for: method, targetSeconds: durationOption.seconds)
    }

    private var durationSelectionIndex: Int {
        WatchDurationOption.allCases.firstIndex(of: durationOption) ?? 0
    }

    private var durationSelectionProgress: CGFloat {
        guard WatchDurationOption.allCases.count > 1 else { return 0 }
        return CGFloat(durationSelectionIndex) / CGFloat(WatchDurationOption.allCases.count - 1)
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(WatchTheme.softFill)
                    .frame(width: 30, height: 30)

                Circle()
                    .stroke(WatchTheme.hairline, lineWidth: 1)
                    .frame(width: 30, height: 30)

                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WatchTheme.foreground)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        Text(BreathingExerciseMath.rhythmText(for: method))
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(WatchTheme.secondary)
            .monospacedDigit()
    }

    private var breathingCircle: some View {
        ZStack {
            Circle()
                .stroke(WatchTheme.hairline, lineWidth: 1)
                .frame(width: 92, height: 92)

            Circle()
                .stroke(WatchTheme.foreground.opacity(0.14), lineWidth: 10)
                .frame(width: 76, height: 76)
                .scaleEffect(BreathingExerciseMath.circleScale(for: currentPhase))
                .animation(.easeInOut(duration: 1), value: currentPhase)

            Circle()
                .stroke(WatchTheme.foreground, lineWidth: 1.5)
                .frame(width: 76, height: 76)
                .scaleEffect(BreathingExerciseMath.circleScale(for: currentPhase))
                .animation(.easeInOut(duration: 1), value: currentPhase)

            VStack(spacing: 2) {
                Text(currentPhase.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WatchTheme.foreground)

                Text("\(currentPhase == .finished ? 0 : countdown)")
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(WatchTheme.foreground)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 94)
    }

    private var status: some View {
        VStack(spacing: 6) {
            Text(currentPhase == .ready ? durationOption.title : "第 \(max(currentCycle, 1)) / \(plan.cycles) 轮")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(WatchTheme.secondary)
                .monospacedDigit()

            if !isActive && currentPhase == .ready {
                durationDragControl
                    .padding(.horizontal, 10)

                HStack(spacing: 0) {
                    ForEach(WatchDurationOption.allCases) { option in
                        Text(option.tickLabel)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(option == durationOption ? WatchTheme.foreground : WatchTheme.muted)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                ProgressView(value: BreathingExerciseMath.progress(elapsed: elapsed, totalDuration: plan.totalDuration, currentPhase: currentPhase))
                    .tint(WatchTheme.foreground)
                    .scaleEffect(x: 1, y: 1.15, anchor: .center)

                Text(BreathingExerciseMath.formattedDuration(plan.totalDuration))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
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
        prepareAudio()
        isActive = true
        startedAt = Date()
        currentCycle = 1
        elapsed = 0
        currentPhase = .inhale
        countdown = method.inhale
        playPhaseCue(for: .inhale)

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
        playHaptic(for: .click)
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
            playPhaseCue(for: currentPhase)
        }
    }

    private func finishSession() {
        currentPhase = .finished
        isActive = false
        countdown = 0
        elapsed = plan.totalDuration
        startedAt = nil
        stopTimer()
        playPhaseCue(for: .finished)
    }

    private func playHaptic(for type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }

    private func playPhaseCue(for phase: BreathingPhase) {
        switch phase {
        case .ready:
            break
        case .inhale:
            playSoftTone(frequency: 523.25, duration: 0.09, startVolume: 0.055, endVolume: 0.001)
            playHaptic(for: .click)
        case .hold:
            playSoftTone(frequency: 659.25, duration: 0.075, startVolume: 0.055, endVolume: 0.001)
            playHaptic(for: .click)
        case .exhale:
            playSoftTone(frequency: 392, duration: 0.12, startVolume: 0.055, endVolume: 0.001)
            playHaptic(for: .click)
        case .finished:
            playSoftTone(frequency: 523.25, duration: 0.68, startVolume: 0.08, endVolume: 0.001)
            playHaptic(for: .click)
        }
    }

    private func prepareAudio() {
        guard !audioPrepared else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            audioPrepared = true
        } catch {
            print("Watch 音频初始化失败: \(error)")
        }
    }

    private func releaseAudio() {
        guard audioPrepared else { return }

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("Watch 音频释放失败: \(error)")
        }
        audioPrepared = false
    }

    private func playSoftTone(frequency: Double, duration: Double, startVolume: Float, endVolume: Float) {
        prepareAudio()
        guard audioPrepared else { return }

        do {
            let player = try AVAudioPlayer(data: wavToneData(
                frequency: frequency,
                duration: duration,
                startVolume: startVolume,
                endVolume: endVolume
            ))
            player.prepareToPlay()
            player.play()
            activeFeedbackPlayers.append(player)

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64((duration + 0.25) * 1_000_000_000))
                activeFeedbackPlayers.removeAll { $0 === player }
            }
        } catch {
            print("Watch 提示音播放失败: \(error)")
        }
    }

    private func updateDurationOption(locationX: CGFloat, width: CGFloat, thumbDiameter: CGFloat) {
        let availableWidth = max(width - thumbDiameter, 1)
        let clampedX = min(max(locationX - (thumbDiameter / 2), 0), availableWidth)
        let rawIndex = (clampedX / availableWidth) * CGFloat(WatchDurationOption.allCases.count - 1)
        let index = min(
            max(Int(rawIndex.rounded()), 0),
            WatchDurationOption.allCases.count - 1
        )
        durationOption = WatchDurationOption.allCases[index]
    }

    private func wavToneData(frequency: Double, duration: Double, startVolume: Float, endVolume: Float) -> Data {
        let sampleRate = 44_100
        let channelCount = 1
        let bitsPerSample = 16
        let bytesPerSample = bitsPerSample / 8
        let frameCount = max(1, Int(Double(sampleRate) * duration))
        let byteRate = sampleRate * channelCount * bytesPerSample
        let blockAlign = channelCount * bytesPerSample

        var sampleData = Data(capacity: frameCount * bytesPerSample)
        let volumeRatio = max(Double(endVolume / startVolume), 0.001)

        for frame in 0..<frameCount {
            let progress = Double(frame) / Double(frameCount)
            let envelope = Double(startVolume) * pow(volumeRatio, progress)
            let wave = sin(2 * Double.pi * frequency * Double(frame) / Double(sampleRate))
            let clamped = max(-1, min(1, wave * envelope))
            var sample = Int16(clamped * Double(Int16.max)).littleEndian
            sampleData.append(Data(bytes: &sample, count: MemoryLayout<Int16>.size))
        }

        var data = Data()
        appendASCII("RIFF", to: &data)
        appendUInt32(UInt32(36 + sampleData.count), to: &data)
        appendASCII("WAVE", to: &data)
        appendASCII("fmt ", to: &data)
        appendUInt32(16, to: &data)
        appendUInt16(1, to: &data)
        appendUInt16(UInt16(channelCount), to: &data)
        appendUInt32(UInt32(sampleRate), to: &data)
        appendUInt32(UInt32(byteRate), to: &data)
        appendUInt16(UInt16(blockAlign), to: &data)
        appendUInt16(UInt16(bitsPerSample), to: &data)
        appendASCII("data", to: &data)
        appendUInt32(UInt32(sampleData.count), to: &data)
        data.append(sampleData)
        return data
    }

    private func appendASCII(_ string: String, to data: inout Data) {
        data.append(string.data(using: .ascii) ?? Data())
    }

    private func appendUInt16(_ value: UInt16, to data: inout Data) {
        var littleEndian = value.littleEndian
        data.append(Data(bytes: &littleEndian, count: MemoryLayout<UInt16>.size))
    }

    private func appendUInt32(_ value: UInt32, to data: inout Data) {
        var littleEndian = value.littleEndian
        data.append(Data(bytes: &littleEndian, count: MemoryLayout<UInt32>.size))
    }
}

private enum WatchDurationOption: CaseIterable, Identifiable {
    case oneMinute
    case threeMinutes
    case fiveMinutes
    case tenMinutes

    var id: String { title }

    var seconds: Int {
        switch self {
        case .oneMinute:
            return 60
        case .threeMinutes:
            return 3 * 60
        case .fiveMinutes:
            return 5 * 60
        case .tenMinutes:
            return 10 * 60
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
        case .tenMinutes:
            return "10 分钟"
        }
    }

    var tickLabel: String {
        switch self {
        case .oneMinute:
            return "1"
        case .threeMinutes:
            return "3"
        case .fiveMinutes:
            return "5"
        case .tenMinutes:
            return "10"
        }
    }

    var next: WatchDurationOption {
        switch self {
        case .oneMinute:
            return .threeMinutes
        case .threeMinutes:
            return .fiveMinutes
        case .fiveMinutes:
            return .tenMinutes
        case .tenMinutes:
            return .oneMinute
        }
    }
}

private struct WatchPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(WatchTheme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                WatchTheme.foreground.opacity(configuration.isPressed ? 0.78 : 1),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }
}

private struct WatchSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(WatchTheme.foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                WatchTheme.softFill.opacity(configuration.isPressed ? 0.72 : 1),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(WatchTheme.hairline, lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        WatchBreathingSessionView(method: BreathingMethod.all[0])
    }
}
