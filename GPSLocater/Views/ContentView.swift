import SwiftUI

// MARK: - ContentView
struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    private enum Tab: Int, CaseIterable, Hashable {
        case home = 0
        case settings = 1
        case tests = 2
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .settings: return "Settings"
            case .tests: return "Tests"
            }
        }
        
        var systemImage: String {
            switch self {
            case .home: return "house.fill"
            case .settings: return "gear"
            case .tests: return "exclamationmark.triangle"
            }
        }
    }
    
    @State private var selectedTab: Tab = .home
    
    private var availableTabs: [Tab] {
        isDebugMode ? [.home, .settings, .tests] : [.home, .settings]
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .settings:
                    SettingsView()
                case .tests:
                    if isDebugMode {
                        ErrorHandlingTestView()
                    } else {
                        HomeView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $selectedTab) {
                        ForEach(availableTabs, id: \.self) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.small) // make it shorter
                    .frame(maxWidth: 300) // optional: constrain width a bit
                }
            }
        }
        .tint(Theme.Colors.accent)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
}
