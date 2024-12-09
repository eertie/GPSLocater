import SwiftUI

import SwiftUI

enum ThemeColor: String, CaseIterable {
    case oceanBlue, system //,purple, green

    var displayName: String {
        switch self {
        case .system: return "System"
        case .oceanBlue: return "Ocean Blue"
        //case .purple: return "Purple"
        //case .green: return "Green"
        }
    }

    var accentColor: Color {
        switch self {
        case .oceanBlue: return Color("#2D7196")
        case .system: return .accentColor
        //case .purple: return Color("#AF52DE")
        //case .green: return Color("#34C759")
        }
    }
}

public class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    static let defaultTheme: ThemeColor = .oceanBlue

    @Published private(set) var current: ThemeColor
    @AppStorage("isDarkMode") var isDarkMode: Bool = true

    // Add computed property for system theme
    var isSystemTheme: Bool {
        return current == .system
    }

    public init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme")
        self.current = ThemeColor(rawValue: savedTheme ?? "") ?? Self.defaultTheme
    }

    func setTheme(_ theme: ThemeColor) {
        current = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
        objectWillChange.send()
    }

    func getTheme() -> ColorTheme {
        switch current {
        case .system: return SystemColorTheme()
     //   case .purple: return PurpleColorTheme()
        case .oceanBlue: return OceanBlueColorTheme()
    //        case .blue: return BlueColorTheme()
    //        case .green: return GreenColorTheme()
        }
    }
}

//
//enum olsThemeColor: String, CaseIterable {
////    case system, blue, green, purple, oceanBlue
//    case system, purple, oceanBlue
//
//}
