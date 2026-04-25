import AVFoundation
import MediaPlayer
import SwiftUI

@MainActor
final class FeedbackService {
    private var activePlayers: [AVAudioPlayer] = []
    private var backgroundPlayer: AVAudioPlayer?
    private var remoteCommandsConfigured = false
    private var isPrepared = false

    func exerciseStarted(mode: SoundMode) {
        guard mode != .silent else { return }

        startBackgroundAudio()

        switch mode {
        case .gentle:
            playTone(frequency: 660, duration: 0.42, startVolume: 0.08, endVolume: 0.001)
        case .classic:
            playTone(frequency: 500, duration: 0.5, startVolume: 0.15)
        case .silent:
            break
        }
    }

    func exerciseModeChanged(mode: SoundMode, isActive: Bool) {
        guard isActive else { return }

        if mode == .silent {
            stopBackgroundAudio()
            clearNowPlaying()
        } else {
            startBackgroundAudio()
        }
    }

    func exerciseStopped() {
        stopBackgroundAudio()
        activePlayers.removeAll()
        clearNowPlaying()

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
            isPrepared = false
        } catch {
            print("音频释放失败: \(error)")
        }
    }

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

    func updateNowPlaying(
        methodName: String,
        phase: BreathingPhase,
        cycle: Int,
        totalCycles: Int,
        elapsed: Int,
        totalDuration: Int,
        isActive: Bool
    ) {
        guard isActive else {
            clearNowPlaying()
            return
        }

        prepare()
        configureRemoteCommands()
        UIApplication.shared.beginReceivingRemoteControlEvents()

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: methodName,
            MPMediaItemPropertyArtist: "\(phase.title) · 第 \(max(cycle, 1)) / \(totalCycles) 轮",
            MPMediaItemPropertyAlbumTitle: "relax",
            MPMediaItemPropertyPlaybackDuration: TimeInterval(totalDuration),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: TimeInterval(elapsed),
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]
    }

    func phaseChanged(phase: BreathingPhase, mode: SoundMode) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        switch mode {
        case .gentle:
            playTone(
                frequency: gentleFrequency(for: phase),
                duration: gentleDuration(for: phase),
                startVolume: 0.055,
                endVolume: 0.001
            )
        case .classic:
            playTone(frequency: classicFrequency(for: phase), duration: classicDuration(for: phase), startVolume: 0.15)
        case .silent:
            break
        }
    }

    func countdownTick(count: Int, mode: SoundMode) {
        guard mode == .classic else { return }

        let frequency = 400 + Double(4 - count) * 200
        playTone(frequency: frequency, duration: 0.1, startVolume: 0.1)
    }

    func finished(mode: SoundMode) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        switch mode {
        case .gentle:
            playTone(frequency: 523.25, duration: 0.68, startVolume: 0.08, endVolume: 0.001)
        case .classic:
            playTone(frequency: classicFrequency(for: .finished), duration: classicDuration(for: .finished), startVolume: 0.15)
        case .silent:
            break
        }
    }

    private func classicFrequency(for phase: BreathingPhase) -> Double {
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

    private func classicDuration(for phase: BreathingPhase) -> Double {
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

    private func gentleFrequency(for phase: BreathingPhase) -> Double {
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

    private func gentleDuration(for phase: BreathingPhase) -> Double {
        switch phase {
        case .inhale:
            return 0.09
        case .hold:
            return 0.075
        case .exhale:
            return 0.12
        case .ready:
            return 0.18
        case .finished:
            return 0.68
        }
    }

    private func playTone(frequency: Double, duration: Double, startVolume: Float, endVolume: Float = 0.01) {
        prepare()
        guard isPrepared else { return }

        do {
            let player = try AVAudioPlayer(data: wavToneData(
                frequency: frequency,
                duration: duration,
                startVolume: startVolume,
                endVolume: endVolume
            ))
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

    private func startBackgroundAudio() {
        prepare()
        guard isPrepared, backgroundPlayer == nil else { return }

        do {
            let player = try AVAudioPlayer(data: silentWavData(duration: 1))
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            backgroundPlayer = player
        } catch {
            print("后台音频保持失败: \(error)")
        }
    }

    private func stopBackgroundAudio() {
        backgroundPlayer?.stop()
        backgroundPlayer = nil
    }

    private func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        UIApplication.shared.endReceivingRemoteControlEvents()
    }

    private func configureRemoteCommands() {
        guard !remoteCommandsConfigured else { return }

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        remoteCommandsConfigured = true
    }

    private func silentWavData(duration: Double) -> Data {
        let sampleRate = 44_100
        let channelCount = 1
        let bitsPerSample = 16
        let bytesPerSample = bitsPerSample / 8
        let frameCount = max(1, Int(Double(sampleRate) * duration))
        let byteRate = sampleRate * channelCount * bytesPerSample
        let blockAlign = channelCount * bytesPerSample
        let sampleData = Data(repeating: 0, count: frameCount * bytesPerSample)

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
