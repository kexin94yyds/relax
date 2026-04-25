import AVFoundation
import SwiftUI

@MainActor
final class FeedbackService {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isPrepared = false

    func prepare() {
        guard !isPrepared else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)

            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)
            try engine.start()
            isPrepared = true
        } catch {
            print("音频初始化失败: \(error)")
        }
    }

    func phaseChanged(phase: BreathingPhase) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        playTone(frequency: frequency(for: phase), duration: duration(for: phase), volume: 0.35)
    }

    func countdownTick() {
        playTone(frequency: 1_100, duration: 0.08, volume: 0.22)
    }

    func finished() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        playTone(frequency: 660, duration: 0.12, volume: 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            self.playTone(frequency: 880, duration: 0.18, volume: 0.32)
        }
    }

    private func frequency(for phase: BreathingPhase) -> Double {
        switch phase {
        case .inhale:
            return 520
        case .hold:
            return 720
        case .exhale:
            return 440
        case .ready:
            return 500
        case .finished:
            return 660
        }
    }

    private func duration(for phase: BreathingPhase) -> Double {
        switch phase {
        case .inhale:
            return 0.24
        case .hold:
            return 0.18
        case .exhale:
            return 0.32
        case .ready:
            return 0.2
        case .finished:
            return 0.18
        }
    }

    private func playTone(frequency: Double, duration: Double, volume: Float) {
        prepare()
        guard isPrepared else { return }

        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        guard sampleRate > 0 else { return }

        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        guard let format, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return }

        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(frameCount)
            let fadeIn = min(progress / 0.12, 1)
            let fadeOut = min((1 - progress) / 0.18, 1)
            let envelope = Float(min(fadeIn, fadeOut))
            let sample = sin(2 * Double.pi * frequency * Double(frame) / sampleRate)
            channel[frame] = Float(sample) * volume * envelope
        }

        if !player.isPlaying {
            player.play()
        }
        player.scheduleBuffer(buffer)
    }
}
