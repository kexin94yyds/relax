import AppKit
import SwiftUI

struct MacMenuBarView: View {
    @ObservedObject var session: MacBreathingSessionModel
    @Environment(\.openWindow) private var openWindow
    @State private var selectedMethodID = BreathingMethod.all[0].id
    @State private var selectedDuration: MacPracticeDuration = .threeMinutes

    private var selectedMethod: BreathingMethod {
        BreathingMethod.all.first { $0.id == selectedMethodID } ?? BreathingMethod.all[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            configuration
            quickStarts
            Divider()
            sessionStatus
            footer
        }
        .padding(18)
        .frame(width: 320)
        .background(RelaxationTheme.paper)
        .onAppear(perform: syncSelectionFromSession)
        .onChange(of: selectedMethodID) { _ in
            prepareSession()
        }
        .onChange(of: selectedDuration) { _ in
            prepareSession()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: session.isActive ? "leaf.fill" : "leaf")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(RelaxationTheme.ink)

            VStack(alignment: .leading, spacing: 2) {
                Text("relax")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RelaxationTheme.ink)

                Text(session.isActive ? "呼吸练习进行中" : "选择一段安静时间")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RelaxationTheme.secondaryInk)
            }

            Spacer()
        }
    }

    private var configuration: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("方法", selection: $selectedMethodID) {
                ForEach(BreathingMethod.all) { method in
                    Text(method.name).tag(method.id)
                }
            }
            .pickerStyle(.menu)
            .disabled(session.isActive)

            Picker("时长", selection: $selectedDuration) {
                ForEach(MacPracticeDuration.allCases) { duration in
                    Text(duration.title).tag(duration)
                }
            }
            .pickerStyle(.segmented)
            .disabled(session.isActive)
        }
    }

    private var quickStarts: some View {
        HStack(spacing: 8) {
            ForEach(MacPracticeDuration.allCases) { duration in
                Button {
                    start(duration: duration)
                } label: {
                    Label("\(duration.shortTitle) 分钟", systemImage: "play.fill")
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(session.isActive)
            }
        }
    }

    private var sessionStatus: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.method.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(RelaxationTheme.ink)

                    Text(session.statusTitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(RelaxationTheme.secondaryInk)
                        .monospacedDigit()
                }

                Spacer()

                Text(session.remainingText)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(RelaxationTheme.ink)
                    .monospacedDigit()
            }

            ProgressView(value: session.progress)
                .tint(RelaxationTheme.ink)

            HStack(spacing: 8) {
                Button {
                    openSessionWindow()
                } label: {
                    Label("打开引导", systemImage: "rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    session.stop()
                } label: {
                    Label("停止", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!session.isActive && session.currentPhase != .finished)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(BreathingExerciseMath.rhythmText(for: selectedMethod))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(RelaxationTheme.mutedInk)
                .monospacedDigit()

            Spacer()

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(RelaxationTheme.secondaryInk)
        }
    }

    private func start(duration: MacPracticeDuration) {
        selectedDuration = duration
        session.start(method: selectedMethod, duration: duration)
        openSessionWindow()
    }

    private func openSessionWindow() {
        openWindow(id: MacWindowID.breathingSession)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func prepareSession() {
        session.prepare(method: selectedMethod, duration: selectedDuration)
    }

    private func syncSelectionFromSession() {
        selectedMethodID = session.method.id
        selectedDuration = session.duration
    }
}
