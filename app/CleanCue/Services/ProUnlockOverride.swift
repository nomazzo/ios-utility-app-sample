import Foundation

nonisolated enum ProUnlockOverride {
    static let launchArgument = "-cleanCueUnlockPro"
    static let userDefaultsKey = "CleanCueDebugUnlockPro"
    static let infoPlistKey = "PortfolioDemoProModeEnabled"

    static func isEnabled(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        userDefaults: UserDefaults = .standard,
        infoDictionary: [String: Any]? = Bundle.main.infoDictionary
    ) -> Bool {
        if let value = Self.value(after: launchArgument, in: arguments) {
            return value == "true" || value == "1" || value == "yes"
        }

        if arguments.contains(launchArgument) {
            return true
        }

        if Self.boolValue(for: infoPlistKey, in: infoDictionary) {
            return true
        }

        #if DEBUG
        if userDefaults.bool(forKey: userDefaultsKey) {
            return true
        }
        #endif

        return false
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(arguments.index(after: index)) else {
            return nil
        }
        return arguments[arguments.index(after: index)]
    }

    private static func boolValue(for key: String, in infoDictionary: [String: Any]?) -> Bool {
        guard let value = infoDictionary?[key] else {
            return false
        }

        if let bool = value as? Bool {
            return bool
        }

        if let number = value as? NSNumber {
            return number.boolValue
        }

        if let string = value as? String {
            return ["true", "1", "yes", "YES"].contains(string)
        }

        return false
    }
}
