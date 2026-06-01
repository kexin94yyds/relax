import Foundation
import SwiftUI

struct WatchHomeView: View {
    @State private var summary = WatchPracticeHistoryStore.shared.summary()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                List {
                    WatchPracticeSummaryRow(summary: summary)
                        .listRowBackground(WatchTheme.background)

                    ForEach(BreathingMethod.all) { method in
                        NavigationLink {
                            WatchBreathingSessionView(method: method)
                        } label: {
                            WatchMethodRow(method: method)
                        }
                        .listRowBackground(WatchTheme.background)
                    }
                }
                .listStyle(.carousel)
                .scrollContentBackground(.hidden)
                .background(WatchTheme.background)
                .padding(.top, 58)

                Text("relax")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WatchTheme.secondary)
                    .padding(.top, 18)
                    .padding(.leading, 30)
                    .accessibilityAddTraits(.isHeader)
            }
            .ignoresSafeArea(.container, edges: .top)
            .background(WatchTheme.background)
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(WatchTheme.foreground)
        .background(WatchTheme.background)
        .onAppear {
            summary = WatchPracticeHistoryStore.shared.summary()
        }
    }
}

private struct WatchPracticeSummaryRow: View {
    let summary: WatchPracticeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("练习记录")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WatchTheme.foreground)

                Spacer(minLength: 4)

                Text(todayDurationText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(WatchTheme.muted)
                    .monospacedDigit()
            }

            HStack(spacing: 8) {
                WatchPracticeMetric(label: "今日", count: summary.todayCount)
                WatchPracticeMetric(label: "本月", count: summary.monthCount)
                WatchPracticeMetric(label: "今年", count: summary.yearCount)
            }

            Text(latestText)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(WatchTheme.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 3)
    }

    private var todayDurationText: String {
        guard summary.todayDurationSeconds > 0 else { return "0分钟" }
        return BreathingExerciseMath.formattedDuration(summary.todayDurationSeconds)
    }

    private var latestText: String {
        guard let latest = summary.latestRecord else {
            return "暂无完成记录"
        }

        let time = latest.completedAt.formatted(date: .omitted, time: .shortened)
        let duration = BreathingExerciseMath.formattedDuration(latest.durationSeconds)
        return "最近 \(time) · \(duration) · \(latest.methodName)"
    }
}

private struct WatchPracticeMetric: View {
    let label: String
    let count: Int

    var body: some View {
        VStack(spacing: 1) {
            Text("\(count)")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(WatchTheme.foreground)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(WatchTheme.muted)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WatchMethodRow: View {
    let method: BreathingMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(method.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(WatchTheme.foreground)
                .lineLimit(2)

            Text(BreathingExerciseMath.rhythmText(for: method))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(WatchTheme.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

struct WatchPracticeRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let methodID: String
    let methodName: String
    let startedAt: Date
    let completedAt: Date
    let durationSeconds: Int
}

struct WatchPracticeSummary: Equatable {
    let todayCount: Int
    let monthCount: Int
    let yearCount: Int
    let todayDurationSeconds: Int
    let latestRecord: WatchPracticeRecord?
}

final class WatchPracticeHistoryStore {
    static let shared = WatchPracticeHistoryStore()

    private let storageKey = "relax_watch_practice_records_v1"
    private let maxStoredRecords = 500
    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .autoupdatingCurrent) {
        self.defaults = defaults
        self.calendar = calendar
    }

    func append(_ record: WatchPracticeRecord) {
        var records = loadRecords()
        records.insert(record, at: 0)
        records = Array(records.prefix(maxStoredRecords))
        save(records)
    }

    func summary(now: Date = Date()) -> WatchPracticeSummary {
        let records = loadRecords()
        let todayRecords = records.filter { calendar.isDate($0.completedAt, inSameDayAs: now) }
        let monthRecords = records.filter { calendar.isDate($0.completedAt, equalTo: now, toGranularity: .month) }
        let yearRecords = records.filter { calendar.isDate($0.completedAt, equalTo: now, toGranularity: .year) }

        return WatchPracticeSummary(
            todayCount: todayRecords.count,
            monthCount: monthRecords.count,
            yearCount: yearRecords.count,
            todayDurationSeconds: todayRecords.reduce(0) { $0 + $1.durationSeconds },
            latestRecord: records.first
        )
    }

    private func loadRecords() -> [WatchPracticeRecord] {
        guard let data = defaults.data(forKey: storageKey) else { return [] }

        do {
            return try JSONDecoder()
                .decode([WatchPracticeRecord].self, from: data)
                .sorted { $0.completedAt > $1.completedAt }
        } catch {
            print("Watch 练习记录读取失败: \(error)")
            return []
        }
    }

    private func save(_ records: [WatchPracticeRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("Watch 练习记录保存失败: \(error)")
        }
    }
}

#Preview {
    WatchHomeView()
}
