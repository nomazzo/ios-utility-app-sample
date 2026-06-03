import Foundation

extension Notification.Name {
    static let cleanCueSettingsDidChange = Notification.Name("cleanCueSettingsDidChange")
}

struct AppSettingsStore {
    private let userDefaults: UserDefaults
    private let key: String
    private let appliesRuntimeOverrides: Bool
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        key: String = "appSettings",
        appliesRuntimeOverrides: Bool = true
    ) {
        self.userDefaults = userDefaults
        self.key = key
        self.appliesRuntimeOverrides = appliesRuntimeOverrides
    }

    func load() -> AppSettings {
        guard let data = userDefaults.data(forKey: key) else {
            return settingsWithRuntimeOverrides(.default)
        }

        let storedSettings = (try? decoder.decode(AppSettings.self, from: data)) ?? .default
        return settingsWithRuntimeOverrides(storedSettings)
    }

    func save(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        userDefaults.set(data, forKey: key)
        NotificationCenter.default.post(name: .cleanCueSettingsDidChange, object: nil)
    }

    func reset() {
        userDefaults.removeObject(forKey: key)
        NotificationCenter.default.post(name: .cleanCueSettingsDidChange, object: nil)
    }

    private func settingsWithRuntimeOverrides(_ settings: AppSettings) -> AppSettings {
        guard appliesRuntimeOverrides else { return settings }

        var settings = settings

        if ProUnlockOverride.isEnabled(userDefaults: userDefaults) {
            settings.proUnlocked = true
            settings.adsDisabled = true
        }

        return settings
    }
}
