//  Views/NewLocationView.swift

import SwiftUI
import CoreLocation
import SwiftData

struct LocationNewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var locationManager: LocationManager
    @State private var isLoading = false
    @State private var locationName = "Unnamed Location"
    @State private var locationDescription = ""
    @State private var isFavorite = false
    @State private var showLocationError = false
    @State private var errorMessage = "Please ensure location services are enabled and try again."
    
    @State private var showValidationError = false
    @State private var validationMessage = ""
    
    
    let onSave: (SavedLocation) -> Void
    
    init(locationManager: LocationManager, onSave: @escaping (SavedLocation) -> Void) {
        self.locationManager = locationManager
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Dimensions.padding) {
                VStack(spacing: Theme.Dimensions.padding) {
                    locationSection
                    
                    // Direct editing of location details
                    VStack(alignment: .leading, spacing: 12) {

                        TextField("Description (Optional)", text: $locationDescription, axis: .vertical)
                            .lineLimit(3...6)
                        
                        Toggle("Is Favorite", isOn: $isFavorite)
                    }
                    .padding()
                    .background(Theme.Colors.cardBackground)
                }
                .padding(.horizontal, Theme.Dimensions.padding)
                
                Spacer()
                saveButtonSection
            }
            .padding(.vertical, Theme.Dimensions.padding)
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("Save Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
            .task {
                if locationManager.currentEntry == nil {
                    await requestLocation()
                } else {
                    updateLocationName()
                }
            }
            .alert("Location Not Available", isPresented: $showLocationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var canSave: Bool {
        !isLoading &&
        locationManager.currentEntry != nil &&
        !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func requestLocation() async {
        guard !isLoading else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            _ = try await locationManager.getCurrentLocation()
            await MainActor.run {
                updateLocationName()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showLocationError = true
                isLoading = false
            }
        }
    }
    
    private func updateLocationName() {
        if let street = locationManager.currentStreet {
            locationName = street
        }
    }
    
    private func validateAndSave() {
        // Trim whitespace
        let trimmedName = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = locationDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate location entry
        guard let currentEntry = locationManager.currentEntry else {
            validationMessage = "Location data is not available"
            showValidationError = true
            return
        }
        
        // Validate coordinates
        guard CLLocationCoordinate2DIsValid(
            CLLocationCoordinate2D(
                latitude: currentEntry.latitude,
                longitude: currentEntry.longitude
            )
        ) else {
            validationMessage = "Invalid location coordinates"
            showValidationError = true
            return
        }
        
        // Validate name
        guard !trimmedName.isEmpty else {
            validationMessage = "Please enter a location name"
            showValidationError = true
            return
        }
        
        do {
            // First, create and save the LocationEntry
            let entry = LocationEntry(
                latitude: currentEntry.latitude,
                longitude: currentEntry.longitude,
                street: currentEntry.street,
                place: currentEntry.place
            )
            modelContext.insert(entry)
            
            // Create SavedLocation with reference to the entry
            let location = SavedLocation(
                name: trimmedName,
                locationDescription: trimmedDescription,
                locationEntry: entry,  // Pass the entry directly
                isFavorite: isFavorite
            )
            modelContext.insert(location)
            
            // Establish bidirectional relationship
            entry.savedLocation = location
            
            // Save the context
            try modelContext.save()
            
            // Call onSave callback
            onSave(location)
            
#if DEBUG
            printDebugInfo(location: location, entry: entry)
#endif
            
            dismiss()
        } catch {
            validationMessage = "Failed to save location: \(error.localizedDescription)"
            showValidationError = true
        }
    }
    
    // Add name field back with validation styling
    private var nameSection: some View {
        TextField("Location Name", text: $locationName)
            .textFieldStyle(.roundedBorder)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        locationName.isEmpty ? Theme.Colors.error : Color.clear,
                        lineWidth: 1
                    )
            )
    }
    
    private var locationSection: some View {
        CurrentLocationView(locationManager: locationManager)
            .padding(.vertical, Theme.Dimensions.padding)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.cardBackground)
    }
    
    private var saveButtonSection: some View {
        Button(action: validateAndSave) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label("Save Location", systemImage: "plus.circle.fill")
//                        .foregroundStyle(Theme.Colors.primaryText)
                        .font(Theme.Typography.buttonText)
                }
                
                Spacer()
            }
            .frame(height: Theme.Dimensions.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadius)
                    .fill(canSave ? Theme.Colors.accent : Theme.Colors.subtle)
            )
            //.foregroundStyle(Theme.Colors.primaryText)
            .foregroundStyle(canSave ? Theme.Colors.buttonText : .secondary)
            .opacity(isLoading ? 0.7 : 1.0)
        }
        .frame(height: Theme.Dimensions.buttonHeight)
        .background(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadius)
                .fill(canSave ? Theme.Colors.accent : Theme.Colors.subtle)
        )
        .disabled(!canSave)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .padding(.horizontal, Theme.Dimensions.padding)
    }
}


#if DEBUG
private func printDebugInfo(location: SavedLocation, entry: LocationEntry) {
    print("Saved Location: \(location.name)")
    print("Location ID: \(location.id)")
    print("Entry ID: \(entry.id)")
    print("Location Entry ID: \(location.locationEntryId)")
    print("Entry coordinates: \(entry.latitude), \(entry.longitude)")
    
    // Verify relationships
    if let locationEntry = location.locationEntry {
        print("Location has entry: ✅")
        print("Entry location matches: \(locationEntry.id == entry.id ? "✅" : "❌")")
    } else {
        print("Location missing entry: ❌")
    }
    
    if let savedLocation = entry.savedLocation {
        print("Entry has location: ✅")
        print("Location matches: \(savedLocation.id == location.id ? "✅" : "❌")")
    } else {
        print("Entry missing location: ❌")
    }
}
#endif

#Preview {
    LocationNewView(
        locationManager: LocationManager.shared,
        onSave: { _ in }
    )
}
