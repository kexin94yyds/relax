enum SoundMode: String, CaseIterable, Identifiable {
    case gentle
    case classic
    case silent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle:
            return "轻柔"
        case .classic:
            return "原版"
        case .silent:
            return "静音"
        }
    }
}
