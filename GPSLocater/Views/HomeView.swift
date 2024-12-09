// Views/HomeView.swift
import SwiftUI
import SwiftData
import CoreLocation

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Query(sort: \SavedLocation.createdAt, order: .reverse) private var savedLocations: [SavedLocation]
    
    @State private var isShowingSaveSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var selectedTheme: ThemeColor
    
    init() {
        _selectedTheme = State(initialValue: ThemeManager.shared.current)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                scrollableContent
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("GPS LOCATER")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.primaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .tint(Theme.Colors.accent)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .task {
            if locationManager.currentEntry == nil {
                await requestLocation()
            }
        }
        .fullScreenCover(isPresented: $isShowingSaveSheet) {
            LocationNewView(locationManager: locationManager) { _ in
                modelContext.refreshAll()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    modelContext.refreshAll()
                }
            }
        }
        .alert("Location Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            LocationCard(
                locationManager: locationManager,
                isLoading: $isLoading,
                onRefresh: requestLocation
            )
            .padding(.vertical, Theme.Dimensions.smallPadding)
            
            SaveLocationButton(
                isPresented: $isShowingSaveSheet,
                locationManager: locationManager,
                isLoading: isLoading
            )
            .padding(.vertical, Theme.Dimensions.smallPadding)
            
            HStack {
                Text("Saved locations")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .padding(.horizontal, Theme.Dimensions.padding)
                    .padding(.vertical, 2)
                Spacer()
            }
        }
        .background(Theme.Colors.primaryBackground)
    }
    
    private var scrollableContent: some View {
        ScrollView {
            LocationsList(savedLocations: savedLocations)
                .padding(.vertical, Theme.Dimensions.smallPadding)
        }
    }
    
    // In HomeView.swift
    private func requestLocation() async {
        guard !isLoading else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            _ = try await locationManager.getCurrentLocation()
        } catch {
            await MainActor.run {
                alertMessage = isDebugMode ? error.localizedDescription : error.userFriendlyMessage
                showingAlert = true
            }
        }
        
        await MainActor.run { isLoading = false }
    }
}

private struct LocationCard: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var locationManager: LocationManager
    @Binding var isLoading: Bool
    let onRefresh: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Dimensions.smallPadding) {
            HStack {
                Text("Last Known Location")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                Spacer()
                RefreshButton(isLoading: $isLoading, action: onRefresh)
            }
            
            Divider()
                .background(Theme.Colors.secondaryText.opacity(0.2))
            
            CurrentLocationView(locationManager: locationManager)
                .padding(.top, 8)
        }
        .padding(Theme.Dimensions.padding)
        .background(Theme.Colors.cardBackground)
        .shadow(color: Color(colorScheme == .dark ? .black : .gray).opacity(0.05), radius: 5)
        .padding(.horizontal, Theme.Dimensions.padding)
        .tint(Theme.Colors.accent)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
}

private struct SaveLocationButton: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var isPresented: Bool
    @ObservedObject var locationManager: LocationManager
    let isLoading: Bool
    
    private var canSave: Bool {
        !isLoading && locationManager.currentEntry != nil
    }
    
    var body: some View {
        Button(action: { isPresented = true }) {
            HStack {
                Image(systemName: "location.app")
                    .imageScale(.large)
                    .font(Theme.Typography.buttonText)
                Text("Save Location")
                    .font(Theme.Typography.buttonText)
                Spacer()
            }
            .padding(.horizontal, Theme.Dimensions.padding)
            .frame(height: Theme.Dimensions.buttonHeight)
            .foregroundStyle(canSave ? Theme.Colors.buttonText : .secondary)
            .background(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadius)
                    .fill(canSave ? Theme.Colors.accent : Theme.Colors.subtle)
            )
        }
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.7)
        .padding(.horizontal, Theme.Dimensions.padding)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
}

private struct RefreshButton: View {
    @Binding var isLoading: Bool
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Theme.Colors.accent)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Theme.Colors.accent)
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

private struct LocationsList: View {
    @Environment(\.modelContext) private var modelContext
    let savedLocations: [SavedLocation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Dimensions.smallPadding) {
            LocationsListSection(savedLocations: savedLocations)
        }
    }
}
