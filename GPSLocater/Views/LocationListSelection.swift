// Views/LocationsListSection.swift

import SwiftUI
import SwiftData
import CoreLocation
import MapKit

struct LocationsListSection: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var selectedLocationId: UUID?
    @State private var isItemLoading = false
    
    
    let savedLocations: [SavedLocation]
    
    @State private var isRefreshing = false
    
    private var favoriteLocations: [SavedLocation] {
        savedLocations.filter { $0.isFavorite }
    }
    
    private var nonFavoriteLocations: [SavedLocation] {
        savedLocations.filter { !$0.isFavorite }
    }
    
    var body: some View {
        Group {
            if isRefreshing {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if savedLocations.isEmpty {
                EmptyLocationView()
            } else {
                VStack(spacing: 0) {
                    if !favoriteLocations.isEmpty {
                        Section {
                            ForEach(favoriteLocations) { location in
                                locationLink(for: location)
                            }
                        }
                    }
                    if !nonFavoriteLocations.isEmpty {
                        Section {
                            ForEach(nonFavoriteLocations) { location in
                                locationLink(for: location)
                            }
                        }
                    }
                }
            }
        }
        .refreshable {
            await refreshData()
        }
    }
    private func locationLink(for location: SavedLocation) -> some View {
        ZStack {
            if isItemLoading && selectedLocationId == location.id {
                LoadingItemView()
            } else {
                NavigationLink {
                    LocationDetailView(savedLocation: location)
                        .modelContext(modelContext)
                } label: {
                    LocationRow(location: location)
                }
                .buttonStyle(PlainButtonStyle())
                .onTapGesture {
                    handleItemTap(location)
                }
            }
        }
    }
    
    private func handleItemTap(_ location: SavedLocation) {
        selectedLocationId = location.id
        isItemLoading = true
        
        Task {
            // Simuleer netwerk vertraging
            //try? await Task.sleep(for: .seconds(4.5))
            
            await MainActor.run {
                isItemLoading = false
                selectedLocationId = nil
            }
        }
    }
    
//    private func handleItemTap(_ location: SavedLocation) {
//        selectedLocationId = location.id
//        isItemLoading = true
//        
//        // Simuleer loading (verwijder dit in productie)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
//            isItemLoading = false
//            selectedLocationId = nil
//        }
//    }
//    
    
    private func refreshData() async {
        isRefreshing = true
        modelContext.refreshAll()
        try? await Task.sleep(for: .seconds(0.5))
        isRefreshing = false
    }
}

private struct EmptyLocationView: View {
    var body: some View {
        ContentUnavailableView(
            "No Saved Locations",
            systemImage: "location.slash",
            description: Text("Save a location to see it here")
        )
    }
}
