// Views/LocationsListSection.swift

import SwiftUI
import SwiftData
import CoreLocation
import MapKit

struct LocationsListSection: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    
    let savedLocations: [SavedLocation]
    
    @State private var editingLocation: SavedLocation? = nil
    
    private var favoriteLocations: [SavedLocation] {
        savedLocations.filter { $0.isFavorite }
    }
    
    private var nonFavoriteLocations: [SavedLocation] {
        savedLocations.filter { !$0.isFavorite }
    }
    
    var body: some View {
        List {
            if savedLocations.isEmpty {
                EmptyLocationView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Theme.Colors.primaryBackground)
            } else {
                if !favoriteLocations.isEmpty {
                    Section {
                        ForEach(favoriteLocations) { location in
                            row(for: location)
                        }
                    }
                }
                if !nonFavoriteLocations.isEmpty {
                    Section {
                        ForEach(nonFavoriteLocations) { location in
                            row(for: location)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.primaryBackground)
        .refreshable {
            await refreshData()
        }
        // Sheet for editing a single location (from swipe action)
        .sheet(isPresented: Binding<Bool>(
            get: { editingLocation != nil },
            set: { if !$0 { editingLocation = nil } }
        )) {
            if let editingLocation {
                EditLocationView(location: editingLocation)
            }
        }
    }
    
    @ViewBuilder
    private func row(for location: SavedLocation) -> some View {
        NavigationLink {
            LocationDetailView(savedLocation: location)
                .modelContext(modelContext)
        } label: {
            LocationRow(location: location)
                .contentShape(Rectangle())
        }
        .listRowInsets(EdgeInsets()) // full-width card look
        .listRowBackground(Theme.Colors.primaryBackground)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Edit
            Button {
                editingLocation = location
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(Theme.Colors.accent)
            
            // Favorite toggle
            Button {
                toggleFavorite(location)
            } label: {
                Label(location.isFavorite ? "Unfavorite" : "Favorite",
                      systemImage: location.isFavorite ? "star.slash" : "star.fill")
            }
            .tint(Theme.Colors.warning)
            
            // Share
            if let shareText = shareText(for: location) {
                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .tint(Theme.Colors.accent)
            }
            
            // Delete
            Button(role: .destructive) {
                deleteLocation(location)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func toggleFavorite(_ location: SavedLocation) {
        location.isFavorite.toggle()
        do {
            try modelContext.save()
        } catch {
            print("Failed to toggle favorite: \(error)")
        }
    }
    
    private func deleteLocation(_ location: SavedLocation) {
        withAnimation {
            modelContext.delete(location)
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete location: \(error)")
            }
        }
    }
    
    private func refreshData() async {
        modelContext.refreshAll()
        try? await Task.sleep(for: .milliseconds(300))
    }
    
    private func shareText(for location: SavedLocation) -> String? {
        guard let entry = location.locationEntry else { return nil }
        let coordinates = "\(entry.latitude),\(entry.longitude)"
        let mapUrl = URL(string: "https://maps.apple.com/?q=\(coordinates)")!
        
        var title = location.locationDescription
        if title.isEmpty {
            title = entry.street ?? "Location"
        }
        
        var shareText = "📍 \(title)"
        shareText += "\n\nOpen in Maps: \(mapUrl.absoluteString)"
        return shareText
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
