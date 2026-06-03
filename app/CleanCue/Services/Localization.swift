import Foundation

enum L10n {
    static var languageCode: String? {
        Locale.current.language.languageCode?.identifier
    }

    static var isDutch: Bool {
        languageCode == "nl"
    }

    static var isSwedish: Bool {
        languageCode == "sv"
    }

    static var isDanish: Bool {
        languageCode == "da"
    }

    static var isNorwegianBokmal: Bool {
        languageCode == "nb" || languageCode == "no"
    }

    static var isSpanish: Bool {
        languageCode == "es"
    }

    static var isPortuguese: Bool {
        languageCode == "pt"
    }

    static var isItalian: Bool {
        languageCode == "it"
    }

    static var isKorean: Bool {
        languageCode == "ko"
    }

    static var isTraditionalChinese: Bool {
        languageCode == "zh"
    }

    static var isFinnish: Bool {
        languageCode == "fi"
    }

    static func text(_ key: String, _ defaultValue: String) -> String {
        Bundle.main.localizedString(forKey: key, value: defaultValue, table: nil)
    }

    static func format(_ key: String, _ defaultValue: String, _ arguments: CVarArg...) -> String {
        String(
            format: text(key, defaultValue),
            locale: Locale.current,
            arguments: arguments
        )
    }
}

extension PresetPlace {
    var localizedDisplayName: String {
        L10n.text(localizedNameKey, displayName)
    }
}

extension PresetTask {
    var localizedDisplayName: String {
        L10n.text(localizedNameKey, displayName)
    }

    var localizedNote: String {
        L10n.text(localizedNoteKey ?? "\(localizedNameKey).note", note)
    }

    var localizedTools: String {
        guard !tools.isEmpty else { return "" }
        return L10n.text("\(localizedNameKey).tools", tools)
    }
}
