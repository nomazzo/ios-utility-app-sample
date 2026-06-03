import SwiftData
import SwiftUI

struct LogsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\CompletionLog.completedAt, order: .reverse)])
    private var logs: [CompletionLog]

    @State private var filter: LogFilter = .all
    @State private var errorMessage: String?

    private let logService = CompletionLogService()

    private var filteredLogs: [CompletionLog] {
        logs.filter { filter.includes($0) }
    }

    private var groupedLogs: [(Date, [CompletionLog])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredLogs) { log in
            calendar.startOfDay(for: log.completedAt)
        }
        return groups
            .map { ($0.key, $0.value.sorted { $0.completedAt > $1.completedAt }) }
            .sorted { $0.0 > $1.0 }
    }

    private var weeklyCompletedLogs: [CompletionLog] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else {
            return []
        }
        return logs.filter {
            $0.actionType == .completed &&
                $0.completedAt >= interval.start &&
                $0.completedAt < interval.end
        }
    }

    private var completedStreakDays: Int {
        let calendar = Calendar.current
        let completedDays = Set(logs.compactMap { log -> Date? in
            guard log.actionType == .completed else { return nil }
            return calendar.startOfDay(for: log.completedAt)
        })

        guard !completedDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let startDay = completedDays.contains(today) ? today : yesterday
        guard completedDays.contains(startDay) else { return 0 }

        var streak = 0
        var day = startDay
        while completedDays.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }
            day = previousDay
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(L10n.text("logs.filter", "フィルタ"), selection: $filter) {
                        ForEach(LogFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if !weeklyCompletedLogs.isEmpty {
                    Section {
                        WeeklyLogSummaryCard(
                            completedCount: weeklyCompletedLogs.count,
                            totalMinutes: weeklyCompletedLogs.reduce(0) { $0 + ($1.task?.estimatedMinutes ?? 0) },
                            streakDays: completedStreakDays
                        )
                    }
                }

                if let errorMessage {
                    Section {
                        ErrorBannerView(message: errorMessage)
                    }
                }

                if groupedLogs.isEmpty {
                    Section {
                        EmptyStateView(
                            title: L10n.text("empty.logs.title", "まだ履歴はありません"),
                            message: L10n.text("empty.logs.message", "掃除を完了すると、ここに履歴が残ります。"),
                            systemImage: "clock.arrow.circlepath"
                        )
                    }
                } else {
                    ForEach(groupedLogs, id: \.0) { day, logs in
                        Section(day.cleanCueDayText) {
                            ForEach(logs) { log in
                                logRow(log)
                                    .swipeActions {
                                        Button(L10n.text("common.delete", "削除"), role: .destructive) {
                                            delete(log)
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .cleanCueScrollableBottomInset()
            .navigationTitle(L10n.text("logs.title", "ログ"))
        }
    }

    private func logRow(_ log: CompletionLog) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.task?.name ?? L10n.text("logs.deletedTask", "削除された掃除"))
                    .font(.headline)
                Spacer()
                Text(log.actionType.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }

            Text(log.task?.place?.name ?? L10n.text("common.noPlace", "場所なし"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label(log.completedAt.formatted(.dateTime.hour().minute()), systemImage: "clock")
                if let originalDueDate = log.originalDueDate {
                    Label(originalDueDate.cleanCueDayText, systemImage: "calendar")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func delete(_ log: CompletionLog) {
        do {
            try logService.delete(log, in: modelContext)
            errorMessage = nil
        } catch {
            errorMessage = L10n.text("logs.deleteFailed", "ログを削除できませんでした。")
        }
    }
}

private struct WeeklyLogSummaryCard: View {
    let completedCount: Int
    let totalMinutes: Int
    let streakDays: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CleanCueTheme.cleanMint)
                .frame(width: 42, height: 42)
                .background(CleanCueTheme.softMint, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("logs.weeklySummary.title", "今週の掃除"))
                    .font(.headline)
                Text(detailText)
                    .font(.subheadline)
                    .foregroundStyle(CleanCueTheme.secondaryText)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var detailText: String {
        if streakDays >= 2 {
            return L10n.format(
                "logs.weeklySummary.detailWithStreak",
                "%d件完了・%d分・%d日連続",
                completedCount,
                totalMinutes,
                streakDays
            )
        }
        return L10n.format("logs.weeklySummary.detail", "%d件完了・%d分", completedCount, totalMinutes)
    }
}

private enum LogFilter: String, CaseIterable {
    case all
    case completed
    case skipped
    case snoozed

    var displayName: String {
        switch self {
        case .all:
            L10n.text("logs.filter.all", "すべて")
        case .completed:
            L10n.text("log.action.completed", "完了")
        case .skipped:
            L10n.text("log.action.skipped", "スキップ")
        case .snoozed:
            L10n.text("log.action.snoozed", "スヌーズ")
        }
    }

    func includes(_ log: CompletionLog) -> Bool {
        switch self {
        case .all:
            true
        case .completed:
            log.actionType == .completed
        case .skipped:
            log.actionType == .skipped || log.actionType == .autoSkippedByPause
        case .snoozed:
            log.actionType == .snoozed
        }
    }
}

#Preview {
    LogsView()
        .modelContainer(PreviewSampleData.makeContainer())
}
