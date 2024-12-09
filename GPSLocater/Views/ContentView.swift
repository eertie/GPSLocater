import SwiftUI

// MARK: - ContentView
struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
            
            // Add error handling tests tab only in DEBUG mode
            if isDebugMode {
                ErrorHandlingTestView()
                    .tabItem {
                        Label("Tests", systemImage: "exclamationmark.triangle")
                    }
                    .tag(2)
            }
        }
        .tint(Theme.Colors.accent)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
}
