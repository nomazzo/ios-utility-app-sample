import SwiftData
import SwiftUI
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\CleaningTask.nextDueDate), SortDescriptor(\CleaningTask.createdAt)])
    private var tasks: [CleaningTask]
    @Query(sort: [SortDescriptor(\PausePeriod.startDate, order: .reverse)])
    private var pausePeriods: [PausePeriod]
    @Query(sort: [SortDescriptor(\CompletionLog.completedAt, order: .reverse)])
    private var completionLogs: [CompletionLog]

    @State private var errorMessage: String?
    @State private var settings = AppSettingsStore().load()
    @State private var showingQuickAdd = false
    @State private var notificationPermissionState: NotificationPermissionState = .notDetermined
    @State private var actionToastMessage: String?
    @State private var actionToastSystemImage = "checkmark.circle.fill"
    @State private var settlingTaskIDs: Set<UUID> = []
    @State private var hasCelebratedAllDoneToday = false

    private let urgencyCalculator = UrgencyCalculator()
    private let pauseService = PauseModeService()
    private var referenceDate: Date { Date() }

    private var sections: TodayTaskSections {
        todayProvider.sections(for: activePausePeriod == nil ? tasks : [], referenceDate: referenceDate)
    }

    private var todayProvider: TodayTaskProvider {
        TodayTaskProvider(maximumRecommendedCount: settings.todayDisplayLimit.recommendedCount)
    }

    private var activePausePeriod: PausePeriod? {
        pauseService.activePausePeriod(from: pausePeriods)
    }

    private var remainingRecommendedTasks: [CleaningTask] {
        sections.allDueToday
    }

    private var remainingRecommendedCount: Int {
        remainingRecommendedTasks.count
    }

    private var remainingRecommendedMinutes: Int {
        remainingRecommendedTasks.reduce(0) { $0 + $1.estimatedMinutes }
    }

    private var completedTodayCount: Int {
        completedTodayLogs.count
    }

    private var completedTodayMinutes: Int {
        completedTodayLogs.reduce(0) { $0 + ($1.task?.estimatedMinutes ?? 0) }
    }

    private var completedTodayLogs: [CompletionLog] {
        let calendar = Calendar.current
        return completionLogs.filter {
            $0.actionType == .completed &&
                calendar.isDate($0.completedAt, inSameDayAs: referenceDate)
        }
    }

    private var todayProgressTotal: Int {
        completedTodayCount + remainingRecommendedCount
    }

    private var todayProgress: Double {
        guard todayProgressTotal > 0 else { return 0 }
        return Double(completedTodayCount) / Double(todayProgressTotal)
    }

    private var shouldShowTodayAchievement: Bool {
        sections.allDueToday.isEmpty &&
            sections.overdue.isEmpty &&
            completedTodayCount > 0
    }

    private var completeHintTaskID: UUID? {
        guard !settings.hasSeenTodayCompleteHint else { return nil }
        return sections.recommended.first?.id ??
            sections.overdue.first?.id ??
            sections.upcomingLight.first?.id
    }

    var body: some View {
        NavigationStack {
            List {
                headerSection

                if shouldShowNotificationPermissionBanner {
                    notificationPermissionBanner
                }

                if let activePausePeriod {
                    pauseBanner(activePausePeriod)
                }

                recommendedSection

                if !sections.overdue.isEmpty {
                    taskSection(
                        title: L10n.text("today.section.overdue", "後回し中"),
                        emptyTitle: "",
                        emptyText: "",
                        tasks: sections.overdue
                    )
                }

                if !sections.upcomingLight.isEmpty {
                    taskSection(
                        title: L10n.text("today.section.upcomingLight", "余裕があれば"),
                        emptyTitle: "",
                        emptyText: "",
                        tasks: sections.upcomingLight
                    )
                }

                if let errorMessage {
                    Section {
                        ErrorBannerView(message: errorMessage)
                    }
                }
            }
            .cleanCueScrollableBottomInset()
            .navigationTitle(L10n.text("today.title", "今日"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingQuickAdd = true
                    } label: {
                        Label(L10n.text("today.add.title", "掃除を追加"), systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingQuickAdd) {
                TodayQuickAddView()
            }
            .overlay(alignment: .top) {
                if let actionToastMessage {
                    FeedbackToastView(message: actionToastMessage, systemImage: actionToastSystemImage)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.96)))
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: actionToastMessage)
            .animation(.spring(response: 0.34, dampingFraction: 0.86), value: sections.recommended.map(\.id))
            .animation(.spring(response: 0.34, dampingFraction: 0.86), value: sections.overdue.map(\.id))
            .animation(.spring(response: 0.34, dampingFraction: 0.86), value: sections.upcomingLight.map(\.id))
            .onReceive(NotificationCenter.default.publisher(for: .cleanCueSettingsDidChange)) { _ in
                settings = AppSettingsStore().load()
                Task {
                    await refreshNotificationPermissionState()
                }
            }
            .task {
                hasCelebratedAllDoneToday = shouldShowTodayAchievement
                await refreshNotificationPermissionState()
            }
            .onChange(of: shouldShowTodayAchievement) { _, isAllDone in
                if !isAllDone {
                    hasCelebratedAllDoneToday = false
                }
            }
        }
    }

    @ViewBuilder
    private var recommendedSection: some View {
        if shouldShowTodayAchievement {
            Section {
                TodayAchievementCard(
                    completedCount: completedTodayCount,
                    completedMinutes: completedTodayMinutes
                )
            }
        } else if sections.recommended.isEmpty, !sections.overdue.isEmpty || !sections.upcomingLight.isEmpty {
            Section(L10n.text("today.section.recommended", "今日のおすすめ")) {
                EmptyStateView(
                    title: L10n.text("empty.today.optional.title", "今日必ずやる掃除はありません"),
                    message: L10n.text("empty.today.optional.message", "余裕があるときの掃除だけ下に表示しています。無理に進めなくても大丈夫です。"),
                    systemImage: "sparkles"
                )
            }
        } else if sections.recommended.isEmpty {
            Section {
                TodayRestEmptyCard()
            }
        } else {
            taskSection(
                title: L10n.text("today.section.recommended", "今日のおすすめ"),
                emptyTitle: L10n.text("empty.today.title", "今日は掃除なしです"),
                emptyText: L10n.text("empty.today.message", "ゆっくりできる日です。次の予定が来たらここに表示します。"),
                tasks: sections.recommended
            )
        }
    }

    private var headerSection: some View {
        Section {
            TodaySummaryCard(
                dateText: referenceDate.cleanCueWeekdayDayText,
                remainingCount: remainingRecommendedCount,
                remainingMinutes: remainingRecommendedMinutes,
                completedCount: completedTodayCount,
                progressTotal: todayProgressTotal,
                progress: todayProgress
            )
        }
    }

    private func pauseBanner(_ period: PausePeriod) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Label(L10n.text("pause.activeBanner.title", "休みモード中"), systemImage: "pause.circle")
                    .font(.headline)
                Text(L10n.format("pause.activeBanner.message", "%@まで、掃除予定は休ませています。", period.endDate.cleanCueDayText))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                NavigationLink(L10n.text("pause.activeBanner.link", "休みモードを確認")) {
                    PauseModeView()
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var shouldShowNotificationPermissionBanner: Bool {
        settings.defaultReminderEnabled && notificationPermissionState == .denied
    }

    private var notificationPermissionBanner: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label(L10n.text("settings.notifications.deniedTitle", "通知がオフになっています"), systemImage: "bell.slash")
                    .font(.headline)
                Text(L10n.text("settings.notifications.deniedHelp", "HomeRoutine Demoの通知はiPhoneの設定でオフになっています。通知を使うには設定アプリで許可してください。"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    openSystemSettings()
                } label: {
                    Label(L10n.text("settings.notifications.openSettings", "設定アプリを開く"), systemImage: "gear")
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 4)
        }
    }

    private func taskSection(title: String, emptyTitle: String, emptyText: String, tasks: [CleaningTask]) -> some View {
        Section(title) {
            if tasks.isEmpty {
                EmptyStateView(
                    title: emptyTitle,
                    message: emptyText,
                    systemImage: "sparkles"
                )
            } else {
                ForEach(tasks) { task in
                    TaskCardView(
                        task: task,
                        urgency: urgencyCalculator.urgency(for: task.nextDueDate, relativeTo: referenceDate),
                        completeAction: { complete(task) },
                        snoozeAction: { snoozeTomorrow(task) },
                        skipAction: { skipThisWeek(task) },
                        showsCompleteHint: completeHintTaskID == task.id,
                        dismissCompleteHint: dismissCompleteHint,
                        isSettlingAway: settlingTaskIDs.contains(task.id)
                    )
                }
            }
        }
    }

    private func refreshNotificationPermissionState() async {
        notificationPermissionState = await NotificationScheduler().permissionState()
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func complete(_ task: CleaningTask) {
        guard !settlingTaskIDs.contains(task.id) else { return }
        let taskName = task.name
        dismissCompleteHint()
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)

        withAnimation(.easeOut(duration: 0.16)) {
            settlingTaskIDs.insert(task.id)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            let didComplete = perform {
                try TaskActionService().complete(task: task, in: modelContext)
            }
            if didComplete {
                if shouldShowTodayAchievement, !hasCelebratedAllDoneToday {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.72)
                    hasCelebratedAllDoneToday = true
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                showActionToast(
                    L10n.format("today.complete.toast", "%@を完了しました", taskName),
                    systemImage: "checkmark.circle.fill"
                )
            } else {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                    settlingTaskIDs.remove(task.id)
                }
            }
        }
    }

    private func snoozeTomorrow(_ task: CleaningTask) {
        let taskName = task.name
        let didSnooze = perform {
            try TaskActionService().snoozeTomorrow(task: task, in: modelContext)
        }
        if didSnooze {
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.42)
            showActionToast(
                L10n.format("today.snooze.toast", "%@を明日にしました", taskName),
                systemImage: "sunrise.fill"
            )
        }
    }

    private func skipThisWeek(_ task: CleaningTask) {
        let taskName = task.name
        let didSkip = perform {
            try TaskActionService().skipThisWeek(task: task, in: modelContext)
        }
        if didSkip {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.48)
            showActionToast(
                L10n.format("today.skip.toast", "今週は%@を休ませました", taskName),
                systemImage: "forward.fill"
            )
        }
    }

    @discardableResult
    private func perform(_ action: () throws -> Void) -> Bool {
        do {
            try withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                try action()
            }
            errorMessage = nil
            Task {
                await rebuildNotifications()
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func showActionToast(_ message: String, systemImage: String) {
        actionToastSystemImage = systemImage
        actionToastMessage = message
        let currentMessage = actionToastMessage
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if actionToastMessage == currentMessage {
                actionToastMessage = nil
            }
        }
    }

    private func dismissCompleteHint() {
        guard !settings.hasSeenTodayCompleteHint else { return }
        settings.hasSeenTodayCompleteHint = true
        AppSettingsStore().save(settings)
    }

    private func rebuildNotifications() async {
        WidgetUpdateService.refresh(tasks: tasks, pausePeriods: pausePeriods)

        do {
            try await NotificationScheduler().rebuildNotifications(
                tasks: tasks,
                pausePeriods: pausePeriods,
                settings: AppSettingsStore().load()
            )
        } catch {
            // 通知再構築に失敗しても、今日画面の操作は完了させる。
        }
    }
}

private struct TodaySummaryCard: View {
    let dateText: String
    let remainingCount: Int
    let remainingMinutes: Int
    let completedCount: Int
    let progressTotal: Int
    let progress: Double

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .imageScale(.small)
                    Text(L10n.text("today.summary.eyebrow", "今日の見通し"))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(CleanCueTheme.primaryBlue)

                Text(dateText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(titleText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text(detailText)
                    .font(.subheadline)
                    .foregroundStyle(CleanCueTheme.secondaryText)
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 8)

            CleanCueProgressRing(progress: progress, label: progressText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .background(
            LinearGradient(
                colors: [
                    CleanCueTheme.softBlue.opacity(0.62),
                    CleanCueTheme.softMint.opacity(0.32),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(progressTotal > 0 ? 1 : 0.68)
        )
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: remainingCount)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: remainingMinutes)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: completedCount)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: progress)
    }

    private var titleText: String {
        if remainingCount == 0 {
            L10n.text("today.summary.noRemaining", "今日は掃除なし")
        } else if L10n.isPortuguese {
            remainingCount == 1 ? "1 tarefa pendente" : "\(remainingCount) tarefas pendentes"
        } else {
            L10n.format("today.summary.remaining", "あと%d件", remainingCount)
        }
    }

    private var detailText: String {
        if remainingCount == 0, completedCount > 0 {
            L10n.text("today.summary.doneForToday", "今日は完了です")
        } else if remainingMinutes == 0 {
            L10n.text("today.subtitle", "今日やる掃除だけ、ここで確認できます。")
        } else {
            L10n.format("today.summary.minutes", "%d分で完了できます", remainingMinutes)
        }
    }

    private var progressText: String {
        guard progressTotal > 0 else {
            return "0/0"
        }
        return L10n.format("today.summary.progress", "%d/%d完了", completedCount, progressTotal)
    }
}

private struct TodayAchievementCard: View {
    let completedCount: Int
    let completedMinutes: Int
    @State private var didAnimateIn = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(CleanCueTheme.cleanMint.opacity(didAnimateIn ? 0.18 : 0.08))
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(CleanCueTheme.cleanMint)
                    .scaleEffect(didAnimateIn ? 1 : 0.74)
                    .symbolEffect(.bounce, value: didAnimateIn)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.text("today.achievement.title", "今日は完了です"))
                    .font(.headline)
                Text(detailText)
                    .font(.subheadline)
                    .foregroundStyle(CleanCueTheme.secondaryText)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            CleanCueTheme.softMint.opacity(didAnimateIn ? 0.88 : 0.24),
                            CleanCueTheme.softBlue.opacity(didAnimateIn ? 0.48 : 0.12),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CleanCueTheme.cleanMint.opacity(didAnimateIn ? 0.18 : 0.04), lineWidth: 1)
        }
        .scaleEffect(didAnimateIn ? 1 : 0.985)
        .opacity(didAnimateIn ? 1 : 0.86)
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.78).delay(0.04)) {
                didAnimateIn = true
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var detailText: String {
        if completedMinutes > 0 {
            return L10n.format("today.achievement.detailWithMinutes", "%d件・%d分の掃除が終わりました。", completedCount, completedMinutes)
        }
        return L10n.format("today.achievement.detail", "%d件の掃除が終わりました。", completedCount)
    }
}

private struct TodayRestEmptyCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(CleanCueTheme.softMint)
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CleanCueTheme.cleanMint)
                Image(systemName: "sparkle")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CleanCueTheme.primaryBlue.opacity(0.72))
                    .offset(x: 18, y: -18)
            }
            .frame(width: 50, height: 50)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("empty.today.title", "今日は掃除なしです"))
                    .font(.headline)
                Text(L10n.text("empty.today.message", "ゆっくりできる日です。次の予定が来たらここに表示します。"))
                    .font(.subheadline)
                    .foregroundStyle(CleanCueTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .background(
            LinearGradient(
                colors: [
                    CleanCueTheme.softMint.opacity(0.64),
                    CleanCueTheme.softBlue.opacity(0.3),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}

private extension TodayDisplayLimit {
    var recommendedCount: Int {
        switch self {
        case .one:
            1
        case .three:
            3
        case .all:
            Int.max
        }
    }
}
