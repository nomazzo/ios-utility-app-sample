import Foundation
import SwiftUI

enum CleanCueTheme {
    static let primaryBlue = Color(red: 0.04, green: 0.52, blue: 1.0)
    static let cleanMint = Color(red: 0.13, green: 0.79, blue: 0.59)
    static let softBlue = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.05, green: 0.16, blue: 0.25, alpha: 1.0)
                : UIColor(red: 0.92, green: 0.96, blue: 1.0, alpha: 1.0)
        }
    )
    static let softMint = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.05, green: 0.22, blue: 0.17, alpha: 1.0)
                : UIColor(red: 0.89, green: 0.99, blue: 0.96, alpha: 1.0)
        }
    )
    static let separator = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.22, green: 0.23, blue: 0.25, alpha: 1.0)
                : UIColor(red: 0.90, green: 0.91, blue: 0.94, alpha: 1.0)
        }
    )
    static let secondaryText = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.63, green: 0.65, blue: 0.70, alpha: 1.0)
                : UIColor(red: 0.54, green: 0.56, blue: 0.60, alpha: 1.0)
        }
    )
    static let warmAttention = Color(red: 0.96, green: 0.64, blue: 0.14)

    static func placeColor(hex: String?) -> Color {
        guard let hex else { return primaryBlue }
        return color(hex: hex)
    }

    static func softPlaceFill(hex: String?) -> Color {
        placeColor(hex: hex).opacity(0.13)
    }

    static func color(hex: String) -> Color {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double

        switch trimmed.count {
        case 6:
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
        default:
            red = 0.04
            green = 0.52
            blue = 1.0
        }

        return Color(red: red, green: green, blue: blue)
    }
}
