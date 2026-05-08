enum SoundMode: String, CaseIterable, Identifiable {
    case gentle
    case classic
    case silent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle:
            return "柔和"
        case .classic:
            return "经典"
        case .silent:
            return "纯震动"
        }
    }
}
