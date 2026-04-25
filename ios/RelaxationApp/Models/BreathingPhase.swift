import SwiftUI

enum BreathingPhase: Equatable {
    case ready
    case inhale
    case hold
    case exhale
    case finished

    var title: String {
        switch self {
        case .ready:
            return "准备开始"
        case .inhale:
            return "吸气"
        case .hold:
            return "保持"
        case .exhale:
            return "呼气"
        case .finished:
            return "练习完成"
        }
    }

    var color: Color {
        switch self {
        case .ready:
            return .accentColor
        case .inhale:
            return Color(red: 76 / 255, green: 175 / 255, blue: 80 / 255)
        case .hold:
            return Color(red: 255 / 255, green: 152 / 255, blue: 0 / 255)
        case .exhale:
            return Color(red: 33 / 255, green: 150 / 255, blue: 243 / 255)
        case .finished:
            return Color(red: 156 / 255, green: 39 / 255, blue: 176 / 255)
        }
    }
}
