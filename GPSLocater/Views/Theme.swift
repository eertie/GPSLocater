import SwiftUI

enum Theme {
    enum Colors {
           private static var currentTheme: ColorTheme {
               ThemeManager.shared.getTheme()
           }

           static var primaryText: Color {
               ThemeManager.shared.isSystemTheme ? Color(.label) : currentTheme.primaryText
           }

           static var secondaryText: Color {
               ThemeManager.shared.isSystemTheme ? Color(.secondaryLabel) : currentTheme.secondaryText
           }

           static var inputBackground: Color {
               ThemeManager.shared.isSystemTheme ? Color(.systemFill) : currentTheme.inputBackground
           }

           static var cardBackground: Color {
               ThemeManager.shared.isSystemTheme ? Color(.secondarySystemBackground) : currentTheme.cardBackground
           }

           static var primaryBackground: Color {
               ThemeManager.shared.isSystemTheme ? Color(.systemBackground) : currentTheme.primaryBackground
           }

           static var accent: Color {
               ThemeManager.shared.isSystemTheme ? Color.accentColor : currentTheme.accent
           }

           static var surface: Color {
               ThemeManager.shared.isSystemTheme ? Color(.tertiarySystemBackground) : currentTheme.surface
           }

           static var highlight: Color {
               ThemeManager.shared.isSystemTheme ? Color.accentColor.opacity(0.2) : currentTheme.highlight
           }

           static var subtle: Color {
               ThemeManager.shared.isSystemTheme ? Color(.systemGray4) : currentTheme.subtle
           }

           static var success: Color {
               ThemeManager.shared.isSystemTheme ? Color.green : currentTheme.success
           }

           static var warning: Color {
               ThemeManager.shared.isSystemTheme ? Color.yellow : currentTheme.warning
           }

           static var error: Color {
               ThemeManager.shared.isSystemTheme ? Color.red : currentTheme.error
           }

           // Add buttonText
           static var buttonText: Color {
               if ThemeManager.shared.isSystemTheme {
                   return ThemeManager.shared.isDarkMode ? .black : .white
               } else {
                   return currentTheme.buttonText
               }
           }

           static var destructive: Color {
               Color("FF3B30")
           }

           static var interactive: Color {
               accent
           }

           static var divider: Color {
               subtle.opacity(0.5)
           }

           enum state {
               static var active: Color { accent }
               static var inactive: Color { subtle }
               static var disabled: Color { secondaryText.opacity(0.5) }
           }

           enum shadow {
               static var color: Color {
                   ThemeManager.shared.isSystemTheme ? Color(.sRGB, white: 0, opacity: 0.1) : Color.black.opacity(0.1)
               }
               static let radius: CGFloat = 4
               static let x: CGFloat = 0
               static let y: CGFloat = 2

               static func opacity(_ value: Double) -> Color {
                   ThemeManager.shared.isSystemTheme ? Color(.sRGB, white: 0, opacity: value) : Color.black.opacity(value)
               }
           }
    }

    enum Dimensions {
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 12
        static let buttonHeight: CGFloat = 44
        static let minimumTapArea: CGFloat = 44
    }

    enum Typography {
        static let caption: Font = .caption
        static let headline: Font = .headline
        static let subheadline: Font = .subheadline
        static let title2: Font = .title2
        static let title3: Font = .title3

        static let body: Font = .body
        static let buttonText: Font = .body.bold()
    }

    enum Elevation {
        struct ShadowModifier: ViewModifier {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat

            func body(content: Content) -> some View {
                content.shadow(color: color, radius: radius, x: x, y: y)
            }
        }

        static func shadow(level: Int) -> ShadowModifier {
            switch level {
            case 0:
                return ShadowModifier(color: Colors.shadow.color, radius: 0, x: 0, y: 0)
            case 1:
                return ShadowModifier(color: Colors.shadow.color, radius: 4, x: 0, y: 2)
            case 2:
                return ShadowModifier(color: Colors.shadow.color, radius: 8, x: 0, y: 4)
            case 3:
                return ShadowModifier(color: Colors.shadow.color, radius: 16, x: 0, y: 8)
            default:
                return ShadowModifier(color: Colors.shadow.color, radius: 4, x: 0, y: 2)
            }
        }
    }
}

extension Color {
    init(_ hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func elevation(_ level: Int) -> some View {
        modifier(Theme.Elevation.shadow(level: level))
    }
}
