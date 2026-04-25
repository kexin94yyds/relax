import AudioToolbox
import SwiftUI

@MainActor
final class FeedbackService {
    func phaseChanged() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        AudioServicesPlaySystemSound(1104)
    }

    func countdownTick() {
        AudioServicesPlaySystemSound(1105)
    }

    func finished() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(1025)
    }
}
