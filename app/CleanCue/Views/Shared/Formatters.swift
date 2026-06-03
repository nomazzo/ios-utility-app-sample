import Foundation

enum CleanCueFormatters {
    static var day: Date.FormatStyle {
        .dateTime.year().month(.wide).day().locale(Locale.current)
    }

    static var weekdayDay: Date.FormatStyle {
        .dateTime.month(.wide).day().weekday(.wide).locale(Locale.current)
    }

    static var time: Date.FormatStyle {
        .dateTime.hour().minute().locale(Locale.current)
    }
}

extension Date {
    var cleanCueDayText: String {
        formatted(CleanCueFormatters.day)
    }

    var cleanCueWeekdayDayText: String {
        formatted(CleanCueFormatters.weekdayDay)
    }

    var cleanCueTimeText: String {
        formatted(CleanCueFormatters.time)
    }
}

extension IntervalUnit {
    var displayName: String {
        switch self {
        case .day:
            L10n.text("interval.unit.days", "Days")
        case .week:
            L10n.text("interval.unit.weeks", "Weeks")
        case .month:
            L10n.text("interval.unit.months", "Months")
        case .year:
            L10n.text("interval.unit.years", "Years")
        }
    }
}

extension FixedRuleType {
    var displayName: String {
        switch self {
        case .weekly:
            L10n.text("fixedRule.weekly", "Weekly")
        case .biweekly:
            L10n.text("fixedRule.biweekly", "Biweekly")
        case .monthlyDay:
            L10n.text("fixedRule.monthly", "Monthly")
        case .monthlyLastDay:
            L10n.text("fixedRule.monthlyLastDay", "Monthly last day")
        case .yearlyDate:
            L10n.text("fixedRule.yearly", "Yearly")
        }
    }
}

extension TaskPriority {
    var displayName: String {
        switch self {
        case .low:
            L10n.text("task.priority.low", "Low")
        case .normal:
            L10n.text("task.priority.normal", "Normal")
        case .high:
            L10n.text("task.priority.high", "High")
        }
    }
}

extension HomeType {
    var displayName: String {
        switch self {
        case .livingAlone:
            L10n.text("homeType.livingAlone", "一人暮らし")
        case .family:
            L10n.text("homeType.family", "家族と暮らす")
        case .shared:
            L10n.text("homeType.shared", "ルームシェア")
        case .other:
            L10n.text("common.other", "その他")
        }
    }
}

extension ReminderTimeChoice {
    var displayName: String {
        switch self {
        case .morning:
            L10n.text("reminder.morning", "朝 8:00")
        case .noon:
            L10n.text("reminder.noon", "昼 12:00")
        case .evening:
            L10n.text("reminder.evening", "夕方 18:00")
        case .night:
            L10n.text("reminder.night", "夜 20:00")
        case .none:
            L10n.text("reminder.none", "通知しない")
        case .custom:
            L10n.text("reminder.custom", "カスタム")
        }
    }
}

extension ReminderStyle {
    var displayName: String {
        switch self {
        case .standard:
            L10n.text("reminderStyle.standard", "当日")
        case .careful:
            L10n.text("reminderStyle.careful", "前日から")
        case .important:
            L10n.text("reminderStyle.important", "3日前から")
        }
    }

    var helpText: String {
        switch self {
        case .standard:
            L10n.text("reminderStyle.standardHelp", "当日の指定時刻に通知します。")
        case .careful:
            L10n.text("reminderStyle.carefulHelp", "前日と当日の指定時刻に通知します。")
        case .important:
            L10n.text("reminderStyle.importantHelp", "3日前、前日、当日の指定時刻に通知します。")
        }
    }
}

extension CompletionActionType {
    var displayName: String {
        switch self {
        case .completed:
            L10n.text("log.action.completed", "完了")
        case .skipped:
            L10n.text("log.action.skipped", "スキップ")
        case .snoozed:
            L10n.text("log.action.snoozed", "スヌーズ")
        case .autoSkippedByPause:
            L10n.text("pause.mode", "休みモード")
        }
    }
}

extension PauseReason {
    var displayName: String {
        switch self {
        case .travel:
            L10n.text("pause.reason.travel", "旅行")
        case .sick:
            L10n.text("pause.reason.sick", "体調不良")
        case .busy:
            L10n.text("pause.reason.busy", "忙しい")
        case .other:
            L10n.text("common.other", "その他")
        }
    }
}

extension UrgencyState {
    var displayName: String {
        switch self {
        case .safe:
            L10n.text("urgency.safe", "まだ大丈夫")
        case .soon:
            L10n.text("urgency.soon", "そろそろ")
        case .today:
            L10n.text("urgency.today", "今日")
        case .overdue:
            L10n.text("urgency.overdue", "後回し中")
        }
    }
}

extension CleaningTask {
    var scheduleSummary: String {
        switch scheduleKind {
        case .fixed:
            guard let fixedRule else { return L10n.text("schedule.fixed", "固定日") }
            switch fixedRule.type {
            case .weekly:
                return L10n.text("fixedRule.weekly", "Weekly")
            case .biweekly:
                return L10n.text("fixedRule.biweekly", "Biweekly")
            case .monthlyDay:
                return L10n.format("schedule.summary.monthlyDay", "毎月%d日", fixedRule.dayOfMonth ?? 1)
            case .monthlyLastDay:
                return L10n.text("fixedRule.monthlyLastDay", "Monthly last day")
            case .yearlyDate:
                return L10n.format("schedule.summary.yearlyDate", "毎年%d月%d日", fixedRule.month ?? 1, fixedRule.day ?? 1)
            }
        case .interval:
            guard let intervalRule else { return L10n.text("schedule.interval", "経過日") }
            switch intervalRule.unit {
            case .day:
                return L10n.format("interval.everyDays", "%d日ごと", intervalRule.value)
            case .week:
                return L10n.format("interval.everyWeeks", "%d週ごと", intervalRule.value)
            case .month:
                return L10n.format("interval.everyMonths", "%dか月ごと", intervalRule.value)
            case .year:
                return L10n.format("interval.everyYears", "%d年ごと", intervalRule.value)
            }
        }
    }
}
