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
    @State private var searchText: String = ""
    @State private var showFavoritesOnly: Bool = false
    @FocusState private var isSearchFocused: Bool
    
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
//            .toolbar {
//                // Keyboard toolbar for dismissing when search is focused
//                ToolbarItemGroup(placement: .keyboard) {
//                    Spacer()
//                    Button("Done") {
//                        isSearchFocused = false
//                    }
//                }
//            }
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
          
            // Show search only when there are more than 15 saved locations
            if savedLocations.count > 15 {
                searchBar
                    .padding(.horizontal, Theme.Dimensions.padding)
                    .padding(.bottom, Theme.Dimensions.smallPadding)
            }
            
//            filterBar
//                .padding(.horizontal, Theme.Dimensions.padding)
//                .padding(.bottom, Theme.Dimensions.smallPadding)
//            
            HStack(spacing: 8) {
                Text("Saved locations")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                
                // Live count badge
                Text("\(filteredSavedLocations.count)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.Colors.cardBackground)
                    .clipShape(Capsule())
                    .foregroundStyle(Theme.Colors.secondaryText)
                
                Spacer()
            }
            .padding(.horizontal, Theme.Dimensions.padding)
            .padding(.vertical, 2)
        }
        .background(Theme.Colors.primaryBackground)
    }
    
    private var scrollableContent: some View {
        // Use a List inside LocationsListSection to enable system swipe actions.
        LocationsList(savedLocations: filteredSavedLocations)
            .scrollDismissesKeyboard(.interactively)
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
    
    // MARK: - Search & Filters
    private var filteredSavedLocations: [SavedLocation] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return savedLocations.filter { location in
            // Basic fields on SavedLocation
            let nameMatches = location.name.localizedCaseInsensitiveContains(text)
            let descriptionMatches = location.locationDescription.localizedCaseInsensitiveContains(text)
            
            // Optional fields on related LocationEntry
            let streetMatches = location.locationEntry?.street?.localizedCaseInsensitiveContains(text) == true
            let placeMatches = location.locationEntry?.place?.localizedCaseInsensitiveContains(text) == true
            
            let matchesSearch =
                text.isEmpty ||
                nameMatches ||
                descriptionMatches ||
                streetMatches ||
                placeMatches
            
            let matchesFavorites = !showFavoritesOnly || location.isFavorite
            
            return matchesSearch && matchesFavorites
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            // Search field container
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.Colors.secondaryText)
                
                TextField("Search saved locations", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .focused($isSearchFocused)
                    .onSubmit { isSearchFocused = false }
                
                if !searchText.isEmpty {
                    Button {
                        withAnimation { searchText = "" }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.Colors.subtle)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Cancel button appears when focused
            if isSearchFocused {
                Button("Cancel") {
                    withAnimation {
                        searchText = ""
                        isSearchFocused = false
                    }
                }
                .foregroundStyle(Theme.Colors.accent)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }
    
    private var filterBar: some View {
        HStack(spacing: 8) {
            FilterPill(
                isOn: $showFavoritesOnly,
                systemImage: "star.fill",
                title: "Favorites"
            )
            
            Spacer(minLength: 0)
        }
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
    let savedLocations: [SavedLocation]
    
    var body: some View {
        LocationsListSection(savedLocations: savedLocations)
    }
}

// MARK: - Filter Pill
private struct FilterPill: View {
    @Binding var isOn: Bool
    let systemImage: String
    let title: String
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn ? Theme.Colors.accent : Theme.Colors.cardBackground)
            .foregroundStyle(isOn ? Theme.Colors.buttonText : Theme.Colors.primaryText)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isOn ? 0.08 : 0.03), radius: isOn ? 4 : 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
