//Views/ColorTheme.swift

import SwiftUI

protocol ColorTheme {
    var primaryText: Color { get }
    var secondaryText: Color { get }
    var inputBackground: Color { get }
    var cardBackground: Color { get }
    var buttonText: Color { get }
    var primaryBackground: Color { get }
    var accent: Color { get }
    var surface: Color { get }
    var highlight: Color { get }
    var subtle: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
}

struct OceanBlueColorTheme: ColorTheme {
    var primaryText: Color {
        ThemeManager.shared.isDarkMode ? .white : Color("1A1A1A")
    }
    
    var secondaryText: Color {
        ThemeManager.shared.isDarkMode ? .gray : Color("666666")
    }
    
    var inputBackground: Color {
        ThemeManager.shared.isDarkMode ? Color("2C2C2E") : .white
    }
    
    var buttonText: Color {
        ThemeManager.shared.isDarkMode ? .white : .white
    }
    
    var cardBackground: Color {
        ThemeManager.shared.isDarkMode ? Color("#1A2830") : Color("#F5F8FA")
//        ThemeManager.shared.isDarkMode ? Color("1C1C1E") : Color("#E6EEF2")
    }
    
    var primaryBackground: Color {
//        ThemeManager.shared.isDarkMode ? Color("#1A2830") : Color("#F5F8FA")
        ThemeManager.shared.isDarkMode ? Color("1C1C1E") : Color("#E6EEF2")
    }
    
    var accent: Color { Color("#2D7196") }
    
    var surface: Color {
        ThemeManager.shared.isDarkMode ? Color("#223540") : Color("#EAF0F4")
    }
    
    var highlight: Color {
        ThemeManager.shared.isDarkMode ? Color("#2D7196").opacity(0.3) : Color("#2D7196").opacity(0.2)
    }
    
    var subtle: Color {
        ThemeManager.shared.isDarkMode ? Color.gray.opacity(0.3) : Color("#F0F4F7")
    }
    
    var success: Color { Color("34C759") }
    var warning: Color { Color("FF9500") }
    var error: Color { Color("FF3B30") }
}

struct BlueColorTheme: ColorTheme {
    var primaryText: Color {
        ThemeManager.shared.isDarkMode ? .white : Color("1A1A1A")
    }
    
    var secondaryText: Color {
        ThemeManager.shared.isDarkMode ? .gray : Color("666666")
    }
    
    var inputBackground: Color {
        ThemeManager.shared.isDarkMode ? Color("2C2C2E") : .white
    }
    
    var buttonText: Color {
        ThemeManager.shared.isDarkMode ? .white : .black
    }
    
    var cardBackground: Color {
        ThemeManager.shared.isDarkMode ? Color("#1A1F35") : Color("#E6E9F5")
    }
    
    var primaryBackground: Color {
        ThemeManager.shared.isDarkMode ? Color("#0A1025") : Color("#F5F6FA")
    }
    
    var accent: Color { Color("#0A84FF") }
    
    var surface: Color {
        ThemeManager.shared.isDarkMode ? Color("#151B30") : Color("#EEF0F7")
    }
    
    var highlight: Color {
        ThemeManager.shared.isDarkMode ? Color("#0A84FF").opacity(0.3) : Color("#0A84FF").opacity(0.2)
    }
    
    var subtle: Color {
        ThemeManager.shared.isDarkMode ? Color.gray.opacity(0.3) : Color("#F0F2F7")
    }
    
    var success: Color { Color("34C759") }
    var warning: Color { Color("FF9500") }
    var error: Color { Color("FF3B30") }
}

struct GreenColorTheme: ColorTheme {
    var primaryText: Color {
        ThemeManager.shared.isDarkMode ? .white : Color("1A1A1A")
    }
    
    var secondaryText: Color {
        ThemeManager.shared.isDarkMode ? .gray : Color("666666")
    }
    
    var inputBackground: Color {
        ThemeManager.shared.isDarkMode ? Color("2C2C2E") : .white
    }
    
    var buttonText: Color {
        ThemeManager.shared.isDarkMode ? .white : .black
    }
    
    var cardBackground: Color {
        ThemeManager.shared.isDarkMode ? Color("#1A2E1F") : Color("#E6F5EA")
    }
    
    var primaryBackground: Color {
        ThemeManager.shared.isDarkMode ? Color("#0A250F") : Color("#F5FAF6")
    }
    
    var accent: Color { Color("#34C759") }
    
    var surface: Color {
        ThemeManager.shared.isDarkMode ? Color("#152A1B") : Color("#EEF7F0")
    }
    
    var highlight: Color {
        ThemeManager.shared.isDarkMode ? Color("#34C759").opacity(0.3) : Color("#34C759").opacity(0.2)
    }
    
    var subtle: Color {
        ThemeManager.shared.isDarkMode ? Color.gray.opacity(0.3) : Color("#F0F7F2")
    }
    
    var success: Color { Color("34C759") }
    var warning: Color { Color("FF9500") }
    var error: Color { Color("FF3B30") }
}

struct PurpleColorTheme: ColorTheme {
    var primaryText: Color {
        ThemeManager.shared.isDarkMode ? .white : Color("1A1A1A")
    }
    
    var secondaryText: Color {
        ThemeManager.shared.isDarkMode ? .gray : Color("666666")
    }
    
    var inputBackground: Color {
        ThemeManager.shared.isDarkMode ? Color("2C2C2E") : .white
    }
    
    var buttonText: Color {
        ThemeManager.shared.isDarkMode ? .white : .black
    }
    
    var cardBackground: Color {
        ThemeManager.shared.isDarkMode ? Color("#261A35") : Color("#F0E6F5")
    }
    
    var primaryBackground: Color {
        ThemeManager.shared.isDarkMode ? Color("#150A25") : Color("#f3ebf7")
//        ThemeManager.shared.isDarkMode ? Color("#150A25") : Color("#F8F5FA")
    }
    
    var accent: Color { Color("#AF52DE") }
    
    var surface: Color {
        ThemeManager.shared.isDarkMode ? Color("#201530") : Color("#F3EEF7")
    }
    
    var highlight: Color {
        ThemeManager.shared.isDarkMode ? Color("#AF52DE").opacity(0.3) : Color("#AF52DE").opacity(0.2)
    }
    
    var subtle: Color {
        ThemeManager.shared.isDarkMode ? Color.gray.opacity(0.3) : Color("#F5F0F7")
    }
    
    var success: Color { Color("34C759") }
    var warning: Color { Color("FF9500") }
    var error: Color { Color("FF3B30") }
}

struct SystemColorTheme: ColorTheme {
    var primaryText: Color {
        ThemeManager.shared.isDarkMode ? .white : .black
    }
    
    var secondaryText: Color {
        Color.secondary
    }
    
    var buttonText: Color {
        ThemeManager.shared.isDarkMode ? .black : .white
    }
    
    var inputBackground: Color {
        ThemeManager.shared.isDarkMode ? Color(uiColor: .systemGray6) : .white
    }
    
    var cardBackground: Color {
        ThemeManager.shared.isDarkMode ? Color(uiColor: .systemGray6) : Color(uiColor: .systemGroupedBackground)
    }
    
    var primaryBackground: Color {
        ThemeManager.shared.isDarkMode ? Color(uiColor: .systemBackground) : Color(uiColor: .systemGroupedBackground)
    }
    
    var accent: Color { Color.accentColor }
    
    var surface: Color {
        ThemeManager.shared.isDarkMode ? Color(uiColor: .secondarySystemGroupedBackground) : Color(uiColor: .secondarySystemGroupedBackground)
    }
    
    var highlight: Color {
        Color.accentColor.opacity(ThemeManager.shared.isDarkMode ? 0.3 : 0.2)
    }
    
    var subtle: Color {
        ThemeManager.shared.isDarkMode ? Color(uiColor: .systemGray5) : Color(uiColor: .systemGray6)
    }
    
    var success: Color { Color(uiColor: .systemGreen) }
    var warning: Color { Color(uiColor: .systemOrange) }
    var error: Color { Color(uiColor: .systemRed) }
}
