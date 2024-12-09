import SwiftUI
import SwiftData
import CoreLocation

struct EditLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationManager: LocationManager
    
    @State private var locationDescription: String
    @State private var isFavorite: Bool
    
    let location: SavedLocation
    
    init(location: SavedLocation) {
        self.location = location
        _locationDescription = State(initialValue: location.locationDescription)
        _isFavorite = State(initialValue: location.isFavorite)
    }
    
    var body: some View {
        ScrollView {
           VStack(spacing: Theme.Dimensions.padding) {
                if let entry = location.locationEntry {
                    let savedAdd = IconTextPair(
                        icon: "calendar",
                        text: location.createdAt.formatted(date: .long, time: .shortened)
                    )
                    
                    LocationAddressView(entry: entry,
                                      additionalItems: [savedAdd])
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                        .padding()
                        .background(Theme.Colors.cardBackground)
                }
                
                // Location details editing
                VStack(alignment: .leading, spacing: 12) {
                    // Description section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryText)
                        
                        TextField("Add description (Optional)", text: $locationDescription, axis: .vertical)
                            .lineLimit(3...6)
//                            .background(Theme.Colors.inputBackground)
                            
                    }
                    
                    // Favorite toggle
                    Toggle("Is Favorite", isOn: $isFavorite)
                        .padding(.top, 8)
                }
                .padding()
                .background(Theme.Colors.cardBackground)
               
                Spacer()
              
                // Save button
                Button(action: saveChanges) {
                    HStack {
                        Image(systemName: "location.app")
                            .imageScale(.large)
                        Text("Save Changes")
                            .font(Theme.Typography.buttonText)
                       // Spacer()
                    }
                    .padding(.horizontal, Theme.Dimensions.padding)
                    .frame(height: Theme.Dimensions.buttonHeight)
                    .foregroundStyle(Theme.Colors.buttonText)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadius)
                            .fill(Theme.Colors.accent)
                    )
                }
                
              
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Edit Location")
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.Colors.primaryBackground)
    }
    
    private func saveChanges() {
        location.locationDescription = locationDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        location.isFavorite = isFavorite
        try? modelContext.save()
        dismiss()
    }
}
