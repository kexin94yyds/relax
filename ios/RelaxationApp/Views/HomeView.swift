import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                RelaxationTheme.paper
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 34) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("呼吸")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundStyle(RelaxationTheme.ink)

                            Text("放松练习")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(RelationTheme.secondaryInk)
                                .textCase(.uppercase)

                            Text("选择一个节奏，跟随提示完成一段安静的呼吸。")
                                .font(.system(size: 16))
                                .foregroundStyle(RelaxationTheme.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 46)

                        VStack(spacing: 0) {
                            ForEach(Array(BreathingMethod.all.enumerated()), id: \.element.id) { index, method in
                                NavigationLink(value: method) {
                                    MethodCardView(method: method, index: index + 1)
                                }
                                .buttonStyle(.plain)

                                if method.id != BreathingMethod.all.last?.id {
                                    Divider()
                                        .overlay(RelaxationTheme.hairline)
                                }
                            }
                        }
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(RelaxationTheme.ink)
                                .frame(height: 1)
                        }
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(RelaxationTheme.ink)
                                .frame(height: 1)
                        }

                        Text("找一个安静的地方，舒适地坐下，专注于你的呼吸")
                            .font(.system(size: 13))
                            .foregroundStyle(RelaxationTheme.mutedInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 22)
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
