import SwiftUI

struct BreathingMethod: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let inhale: Int
    let hold: Int
    let exhale: Int
    let cycles: Int
    let color: Color

    var cycleDuration: Int {
        inhale + hold + exhale
    }

    var totalDuration: Int {
        cycleDuration * cycles
    }
}

extension BreathingMethod {
    static let all: [BreathingMethod] = [
        BreathingMethod(
            id: "1",
            name: "4-7-8 呼吸法",
            description: "经典的放松呼吸法：4秒吸气，7秒保持，8秒呼气",
            inhale: 4,
            hold: 7,
            exhale: 8,
            cycles: 5,
            color: Color(red: 74 / 255, green: 144 / 255, blue: 226 / 255)
        ),
        BreathingMethod(
            id: "2",
            name: "简单放松",
            description: "简单的5秒呼吸循环，适合快速放松",
            inhale: 5,
            hold: 0,
            exhale: 5,
            cycles: 10,
            color: Color(red: 126 / 255, green: 211 / 255, blue: 33 / 255)
        ),
        BreathingMethod(
            id: "3",
            name: "深度放松",
            description: "深度呼吸：6秒吸气，3秒保持，8秒呼气",
            inhale: 6,
            hold: 3,
            exhale: 8,
            cycles: 6,
            color: Color(red: 245 / 255, green: 166 / 255, blue: 35 / 255)
        ),
        BreathingMethod(
            id: "4",
            name: "冥想呼吸",
            description: "适合冥想的缓慢呼吸：8秒吸气，4秒保持，8秒呼气",
            inhale: 8,
            hold: 4,
            exhale: 8,
            cycles: 4,
            color: Color(red: 155 / 255, green: 89 / 255, blue: 182 / 255)
        ),
        BreathingMethod(
            id: "5",
            name: "共振呼吸",
            description: "每分钟6次呼吸：4秒吸气，6秒呼气，镇静神经系统",
            inhale: 4,
            hold: 0,
            exhale: 6,
            cycles: 8,
            color: Color(red: 231 / 255, green: 76 / 255, blue: 60 / 255)
        ),
        BreathingMethod(
            id: "6",
            name: "晨间练习",
            description: "完整的晨间放松练习：深呼吸准备 + 身体扫描",
            inhale: 4,
            hold: 2,
            exhale: 6,
            cycles: 6,
            color: Color(red: 142 / 255, green: 68 / 255, blue: 173 / 255)
        )
    ]
}
