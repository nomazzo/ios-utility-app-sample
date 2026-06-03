import Foundation

struct EntitlementStore {
    private let settingsStore: AppSettingsStore

    init(settingsStore: AppSettingsStore = AppSettingsStore()) {
        self.settingsStore = settingsStore
    }

    var isProUnlocked: Bool {
        settingsStore.load().proUnlocked
    }

    func updateProUnlocked(_ isUnlocked: Bool) {
        var settings = settingsStore.load()
        settings.proUnlocked = isUnlocked
        settings.adsDisabled = true
        settingsStore.save(settings)
    }
}
