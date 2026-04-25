import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 102 / 255, green: 126 / 255, blue: 234 / 255),
                        Color(red: 118 / 255, green: 75 / 255, blue: 162 / 255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("选择放松方式")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text("选择一个呼吸练习方法开始你的放松之旅")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.88))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 36)

                        LazyVStack(spacing: 16) {
                            ForEach(BreathingMethod.all) { method in
                                NavigationLink(value: method) {
                                    MethodCardView(method: method)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("找一个安静的地方，舒适地坐下，专注于你的呼吸")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationDestination(for: BreathingMethod.self) { method in
                BreathingView(method: method)
            }
        }
    }
}

#Preview {
    HomeView()
}
