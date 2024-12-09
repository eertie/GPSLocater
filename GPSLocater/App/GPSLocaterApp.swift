// App/GPSLocaterApp.swift

import SwiftUI
import SwiftData


@main
struct GPSLocaterApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var isShowingLaunchScreen = true
    
    
    let container: ModelContainer
    
    init() {
        // Delete the existing store
        //        let url = URL.applicationSupportDirectory
        //            .appendingPathComponent("default.store")
        //        try? FileManager.default.removeItem(at: url)
        //

        // Read DEBUG from environment
        if let debugValue = ProcessInfo.processInfo.environment["DEBUG"] {
           UserDefaults.standard.set(debugValue.lowercased() == "true", forKey: "DEBUG_MODE")
        }

        configureInitialTheme()
        
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(
                for: LocationEntry.self,
                     SavedLocation.self,
                configurations: config
            )
            
            // Cleanup any orphaned SavedLocations
            try container.mainContext.cleanupOrphanedLocations()
            
            
        } catch {
            print("Failed to initialize ModelContainer: \(error)")
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    
    var body: some Scene {
            WindowGroup {
                ZStack {
                    if isShowingLaunchScreen {
                        LaunchScreenView()
                            .transition(.opacity)
                            .zIndex(1)
                    }
                    
                    ContentView()
                        .environmentObject(themeManager)
                        .environmentObject(locationManager)                        
                        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                        .modelContainer(container)
                        .zIndex(0)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isShowingLaunchScreen = false
                        }
                    }
                }
            }
        }   
}

extension ModelContext {
    func cleanupOrphanedLocations() throws {
        let descriptor = FetchDescriptor<SavedLocation>(
            predicate: #Predicate<SavedLocation> {
                $0.locationEntry == nil
            }
        )
        
        let orphanedLocations = try fetch(descriptor)
        
        if !orphanedLocations.isEmpty {
            print("Found \(orphanedLocations.count) orphaned locations to delete")
            orphanedLocations.forEach { delete($0) }
            try save()
        }
    }
}

#if DEBUG
extension ModelContainer {
    static var preview: ModelContainer = {
        try! ModelContainer(
            for: LocationEntry.self, SavedLocation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: false)
        )
    }()
}
#endif

private func configureInitialTheme() {
    
//    ThemeManager.shared.setTheme(.oceanBlue)
    print("InitialTheme configured...")
    
    let defaults = UserDefaults.standard
    let isFirstLaunch = !defaults.bool(forKey: "hasLaunchedBefore")
    if isFirstLaunch {
        print("First launch setup")
        defaults.set(true, forKey: "hasLaunchedBefore")
        ThemeManager.shared.setTheme(.oceanBlue) // Set default theme
    }
}





