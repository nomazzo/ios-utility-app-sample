import Foundation

nonisolated struct AppSettings: Codable, Equatable, Sendable {
    var hasCompletedOnboarding: Bool
    var defaultReminderEnabled: Bool
    var defaultReminderTimeMinutes: Int
    var defaultCalendarIdentifier: Calendar.Identifier
    var firstWeekday: Int?
    var languageCode: String?
    var homeType: HomeType
    var proUnlocked: Bool
    var adsDisabled: Bool
    var softHapticsEnabled: Bool
    var appearance: AppAppearance
    var todayDisplayLimit: TodayDisplayLimit
    var urgencyExpressionStyle: UrgencyExpressionStyle
    var weekStartPreference: WeekStartPreference
    var hasSeenTodayCompleteHint: Bool

    init(
        hasCompletedOnboarding: Bool = false,
        defaultReminderEnabled: Bool = true,
        defaultReminderTimeMinutes: Int = 9 * 60,
        defaultCalendarIdentifier: Calendar.Identifier = .gregorian,
        firstWeekday: Int? = nil,
        languageCode: String? = nil,
        homeType: HomeType = .other,
        proUnlocked: Bool = false,
        adsDisabled: Bool = true,
        softHapticsEnabled: Bool = true,
        appearance: AppAppearance = .system,
        todayDisplayLimit: TodayDisplayLimit = .three,
        urgencyExpressionStyle: UrgencyExpressionStyle = .gentle,
        weekStartPreference: WeekStartPreference = .automatic,
        hasSeenTodayCompleteHint: Bool = false
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.defaultReminderEnabled = defaultReminderEnabled
        self.defaultReminderTimeMinutes = defaultReminderTimeMinutes
        self.defaultCalendarIdentifier = defaultCalendarIdentifier
        self.firstWeekday = firstWeekday
        self.languageCode = languageCode
        self.homeType = homeType
        self.proUnlocked = proUnlocked
        self.adsDisabled = adsDisabled
        self.softHapticsEnabled = softHapticsEnabled
        self.appearance = appearance
        self.todayDisplayLimit = todayDisplayLimit
        self.urgencyExpressionStyle = urgencyExpressionStyle
        self.weekStartPreference = weekStartPreference
        self.hasSeenTodayCompleteHint = hasSeenTodayCompleteHint
    }

    static let `default` = AppSettings()

    private enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case defaultReminderEnabled
        case defaultReminderTimeMinutes
        case defaultCalendarIdentifier
        case firstWeekday
        case languageCode
        case homeType
        case proUnlocked
        case adsDisabled
        case softHapticsEnabled
        case appearance
        case todayDisplayLimit
        case urgencyExpressionStyle
        case weekStartPreference
        case hasSeenTodayCompleteHint
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        self.defaultReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .defaultReminderEnabled) ?? true
        self.defaultReminderTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultReminderTimeMinutes) ?? 9 * 60
        self.defaultCalendarIdentifier = try container.decodeIfPresent(Calendar.Identifier.self, forKey: .defaultCalendarIdentifier) ?? .gregorian
        self.firstWeekday = try container.decodeIfPresent(Int.self, forKey: .firstWeekday)
        self.languageCode = try container.decodeIfPresent(String.self, forKey: .languageCode)
        self.homeType = try container.decodeIfPresent(HomeType.self, forKey: .homeType) ?? .other
        self.proUnlocked = try container.decodeIfPresent(Bool.self, forKey: .proUnlocked) ?? false
        self.adsDisabled = try container.decodeIfPresent(Bool.self, forKey: .adsDisabled) ?? true
        self.softHapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .softHapticsEnabled) ?? true
        self.appearance = try container.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
        self.todayDisplayLimit = try container.decodeIfPresent(TodayDisplayLimit.self, forKey: .todayDisplayLimit) ?? .three
        self.urgencyExpressionStyle = try container.decodeIfPresent(UrgencyExpressionStyle.self, forKey: .urgencyExpressionStyle) ?? .gentle
        self.weekStartPreference = try container.decodeIfPresent(WeekStartPreference.self, forKey: .weekStartPreference) ?? .automatic
        self.hasSeenTodayCompleteHint = try container.decodeIfPresent(Bool.self, forKey: .hasSeenTodayCompleteHint) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(defaultReminderEnabled, forKey: .defaultReminderEnabled)
        try container.encode(defaultReminderTimeMinutes, forKey: .defaultReminderTimeMinutes)
        try container.encode(defaultCalendarIdentifier, forKey: .defaultCalendarIdentifier)
        try container.encodeIfPresent(firstWeekday, forKey: .firstWeekday)
        try container.encodeIfPresent(languageCode, forKey: .languageCode)
        try container.encode(homeType, forKey: .homeType)
        try container.encode(proUnlocked, forKey: .proUnlocked)
        try container.encode(adsDisabled, forKey: .adsDisabled)
        try container.encode(softHapticsEnabled, forKey: .softHapticsEnabled)
        try container.encode(appearance, forKey: .appearance)
        try container.encode(todayDisplayLimit, forKey: .todayDisplayLimit)
        try container.encode(urgencyExpressionStyle, forKey: .urgencyExpressionStyle)
        try container.encode(weekStartPreference, forKey: .weekStartPreference)
        try container.encode(hasSeenTodayCompleteHint, forKey: .hasSeenTodayCompleteHint)
    }
}
