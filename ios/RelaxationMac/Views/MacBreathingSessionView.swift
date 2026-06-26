import SwiftUI

struct MacBreathingSessionView: View {
    @ObservedObject var session: MacBreathingSessionModel

    var body: some View {
        ZStack {
            RelaxationTheme.paper
                .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                breathingCircle
                progressSection
                controls
            }
            .padding(28)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(session.method.name)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(RelaxationTheme.ink)
                .lineLimit(1)

            Text(BreathingExerciseMath.rhythmText(for: session.method))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(RelaxationTheme.secondaryInk)
                .monospacedDigit()
        }
    }

    private var breathingCircle: some View {
        ZStack {
            Circle()
                .stroke(RelaxationTheme.hairline, lineWidth: 1)
                .frame(width: 250, height: 250)

            Circle()
                .stroke(session.method.color.opacity(0.16), lineWidth: 22)
                .frame(width: 206, height: 206)
                .scaleEffect(BreathingExerciseMath.circleScale(for: session.currentPhase))
                .animation(.easeInOut(duration: 1), value: session.currentPhase)

            Circle()
                .stroke(RelaxationTheme.ink, lineWidth: 2)
                .frame(width: 206, height: 206)
                .scaleEffect(BreathingExerciseMath.circleScale(for: session.currentPhase))
                .animation(.easeInOut(duration: 1), value: session.currentPhase)

            VStack(spacing: 10) {
                Text(session.currentPhase.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RelaxationTheme.ink)

                Text("\(session.currentPhase == .finished ? 0 : session.countdown)")
                    .font(.system(size: 58, weight: .semibold, design: .monospaced))
                    .foregroundStyle(RelaxationTheme.ink)
                    .monospacedDigit()

                Text(session.currentPhase == .ready ? session.duration.title : "第 \(max(session.currentCycle, 1)) / \(session.plan.cycles) 轮")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(RelaxationTheme.secondaryInk)
                    .monospacedDigit()
            }
        }
        .frame(height: 270)
    }

    private var progressSection: some View {
        VStack(spacing: 10) {
            ProgressView(value: session.progress)
                .tint(RelaxationTheme.ink)

            HStack {
                Text("\(Int((session.progress * 100).rounded()))%")
                Spacer()
                Text("剩余 \(session.remainingText)")
            }
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundStyle(RelaxationTheme.mutedInk)
            .monospacedDigit()
        }
    }

    @ViewBuilder
    private var controls: some View {
        if session.isActive {
            Button {
                session.stop()
            } label: {
                Label("停止", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        } else if session.currentPhase == .finished {
            HStack(spacing: 10) {
                Button {
                    session.restart()
                } label: {
                    Label("重新开始", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    session.stop()
                } label: {
                    Label("完成", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
        } else {
            Button {
                session.start()
            } label: {
                Label("开始", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

#Preview {
    MacBreathingSessionView(session: MacBreathingSessionModel())
}
