import AVFoundation
import Foundation

@MainActor
final class MacFeedbackService {
    private var activePlayers: [AVAudioPlayer] = []

    func exerciseStarted(phase: BreathingPhase) {
        phaseChanged(phase: phase)
    }

    func exerciseStopped() {
        activePlayers.removeAll()
    }

    func phaseChanged(phase: BreathingPhase) {
        playTone(
            frequency: frequency(for: phase),
            duration: duration(for: phase),
            startVolume: 0.08,
            endVolume: 0.001
        )
    }

    func countdownTick(count: Int) {
        let frequency = 440 + Double(4 - count) * 90
        playTone(frequency: frequency, duration: 0.08, startVolume: 0.045, endVolume: 0.001)
    }

    func finished() {
        playTone(frequency: 523.25, duration: 0.34, startVolume: 0.09, endVolume: 0.001)
    }

    private func frequency(for phase: BreathingPhase) -> Double {
        switch phase {
        case .inhale:
            return 523.25
        case .hold:
            return 659.25
        case .exhale:
            return 392
        case .ready:
            return 440
        case .finished:
            return 523.25
        }
    }

    private func duration(for phase: BreathingPhase) -> TimeInterval {
        switch phase {
        case .inhale:
            return 0.18
        case .hold:
            return 0.12
        case .exhale:
            return 0.22
        case .ready:
            return 0.12
        case .finished:
            return 0.34
        }
    }

    private func playTone(
        frequency: Double,
        duration: TimeInterval,
        startVolume: Double,
        endVolume: Double
    ) {
        let data = Self.toneData(
            frequency: frequency,
            duration: duration,
            startVolume: startVolume,
            endVolume: endVolume
        )

        do {
            let player = try AVAudioPlayer(data: data)
            activePlayers.append(player)
            player.prepareToPlay()
            player.play()

            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.2) { [weak self, weak player] in
                guard let player else { return }
                self?.activePlayers.removeAll { $0 === player }
            }
        } catch {
            print("Mac 音效播放失败: \(error)")
        }
    }

    private static func toneData(
        frequency: Double,
        duration: TimeInterval,
        startVolume: Double,
        endVolume: Double
    ) -> Data {
        let sampleRate = 44_100
        let channels = 1
        let bitsPerSample = 16
        let sampleCount = max(1, Int(Double(sampleRate) * duration))
        let dataSize = sampleCount * channels * MemoryLayout<Int16>.size
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8

        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        append(UInt32(36 + dataSize).littleEndian, to: &data)
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        append(UInt32(16).littleEndian, to: &data)
        append(UInt16(1).littleEndian, to: &data)
        append(UInt16(channels).littleEndian, to: &data)
        append(UInt32(sampleRate).littleEndian, to: &data)
        append(UInt32(byteRate).littleEndian, to: &data)
        append(UInt16(blockAlign).littleEndian, to: &data)
        append(UInt16(bitsPerSample).littleEndian, to: &data)
        data.append(contentsOf: "data".utf8)
        append(UInt32(dataSize).littleEndian, to: &data)

        for sampleIndex in 0..<sampleCount {
            let progress = Double(sampleIndex) / Double(max(sampleCount - 1, 1))
            let envelope = startVolume + (endVolume - startVolume) * progress
            let phase = 2 * Double.pi * frequency * Double(sampleIndex) / Double(sampleRate)
            let sample = Int16(max(min(sin(phase) * envelope * Double(Int16.max), Double(Int16.max)), Double(Int16.min)))
            append(sample.littleEndian, to: &data)
        }

        return data
    }

    private static func append<T>(_ value: T, to data: inout Data) {
        var value = value
        withUnsafeBytes(of: &value) { bytes in
            data.append(contentsOf: bytes)
        }
    }
}
