import AVFoundation
import SwiftUI

@MainActor
final class FeedbackService {
    private var activePlayers: [AVAudioPlayer] = []
    private var isPrepared = false

    func prepare() {
        guard !isPrepared else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            isPrepared = true
        } catch {
            print("音频初始化失败: \(error)")
        }
    }

    func phaseChanged(phase: BreathingPhase) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        playTone(frequency: frequency(for: phase), duration: duration(for: phase), startVolume: 0.15)
    }

    func countdownTick(count: Int) {
        let frequency = 400 + Double(4 - count) * 200
        playTone(frequency: frequency, duration: 0.1, startVolume: 0.1)
    }

    func finished() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        playTone(frequency: frequency(for: .finished), duration: duration(for: .finished), startVolume: 0.15)
    }

    private func frequency(for phase: BreathingPhase) -> Double {
        switch phase {
        case .inhale:
            return 600
        case .hold:
            return 800
        case .exhale:
            return 1_000
        case .ready:
            return 500
        case .finished:
            return 400
        }
    }

    private func duration(for phase: BreathingPhase) -> Double {
        switch phase {
        case .inhale:
            return 0.3
        case .hold:
            return 0.2
        case .exhale:
            return 0.4
        case .ready:
            return 0.5
        case .finished:
            return 0.8
        }
    }

    private func playTone(frequency: Double, duration: Double, startVolume: Float) {
        prepare()
        guard isPrepared else { return }

        do {
            let player = try AVAudioPlayer(data: wavToneData(frequency: frequency, duration: duration, startVolume: startVolume))
            player.prepareToPlay()
            player.play()
            activePlayers.append(player)

            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
                self.activePlayers.removeAll { $0 === player }
            }
        } catch {
            print("播放提示音失败: \(error)")
        }
    }

    private func wavToneData(frequency: Double, duration: Double, startVolume: Float) -> Data {
        let sampleRate = 44_100
        let channelCount = 1
        let bitsPerSample = 16
        let bytesPerSample = bitsPerSample / 8
        let frameCount = max(1, Int(Double(sampleRate) * duration))
        let byteRate = sampleRate * channelCount * bytesPerSample
        let blockAlign = channelCount * bytesPerSample

        var sampleData = Data(capacity: frameCount * bytesPerSample)
        let endVolume = Float(0.01)
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
