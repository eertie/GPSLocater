// MARK: - LocationDetailView.swift

import SwiftUI
import MapKit
import SwiftData

struct LocationDetailView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var weatherManager: WeatherManager

    @State private var currentWeather: WeatherData?
    @State private var region: MKCoordinateRegion
    @State private var selectedMapType: MKMapType = .standard
    @State private var showingDeleteConfirmation = false
    @State private var showWeather = false
    @State private var showMap = true

    let savedLocation: SavedLocation

    // MARK: - Computed Properties
    private var isDirectionsAvailable: Bool {
        guard let entry = savedLocation.locationEntry,
              let distance = calculateDistance(to: entry) else {
            return false
        }
        return distance >= 30
    }

    // MARK: - Initialization
    init(savedLocation: SavedLocation) {
        self.savedLocation = savedLocation

        if let entry = savedLocation.locationEntry {
            let coordinate = CLLocationCoordinate2D(
                latitude: entry.latitude,
                longitude: entry.longitude
            )
            _region = State(initialValue: MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    // MARK: - Body
    var body: some View {
        Group {
            if let entry = savedLocation.locationEntry {
                mainContent(entry: entry)
            } else {
                ContentUnavailableView(
                    "Location Data Unavailable",
                    systemImage: "location.slash",
                    description: Text("The location data for this entry could not be found.")
                )
            }
        }
        .navigationTitle("Location Details")
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .confirmationDialog(
            "Delete Location",
            isPresented: $showingDeleteConfirmation,
            actions: DeleteConfirmationActions
        )
    }

    // MARK: - Content Views
    private func mainContent(entry: LocationEntry) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                locationSection(entry)
              //     .padding(.horizontal, Theme.Dimensions.smallPadding)

                actionSection(entry)
                //    .padding(Theme.Dimensions.smallPadding)
//                    .background(Theme.Colors.cardBackground)
                    //.padding(.horizontal, Theme.Dimensions.padding)
                    //.padding(.vertical, Theme.Dimensions.smallPadding)


//                if !isDirectionsAvailable {
                    mapSection(entry)
                        .padding(.horizontal, Theme.Dimensions.padding)
//                }
                Spacer()
                weatherSection(entry)
//                    .padding(.horizontal, Theme.Dimensions.padding)
            }
//            .padding(.vertical, Theme.Dimensions.padding)
        }
        .background(Theme.Colors.primaryBackground)
    }

    private func locationSection(_ entry: LocationEntry) -> some View {
           NavigationLink(destination: EditLocationView(location: savedLocation)) {

               if isDirectionsAvailable {

                   if let distance = calculateDistance(to: entry) {
                       LocationRow(
                           location: savedLocation,
                           showLatLon: false,
                           additionalItems: [
                               IconTextPair(
                                   icon: "arrow.triangle.branch",
                                   text: "Distance to: \(savedLocation.locationEntry?.street ?? "location"): \(formatDistance(distance))"
                               )
                           ]
                       )
                   } else {
                       LocationRow(location: savedLocation, showLatLon: true)
                   }

               } else {
                   LocationRow(location: savedLocation, showLatLon: true)
               }

           }
           .buttonStyle(PlainButtonStyle())
           .padding(.bottom, 2)
       }

    private func actionSection(_ entry: LocationEntry) -> some View {
        ActionButtons(
            entry: entry,
            isDirectionsAvailable: isDirectionsAvailable,
            onShare: { shareLocation(entry: entry) },
            onDirections: { openInMaps(entry: entry) }
        )
        //.frame(height: 15)
        .padding(.vertical, 15)
    }

    private func mapSection(_ entry: LocationEntry) -> some View {
        MapSection(
            showMap: $showMap,
            selectedMapType: $selectedMapType,
            entry: entry,
            region: region
        )
        .padding(.bottom, 1)
    }

    private func weatherSection(_ entry: LocationEntry) -> some View {
        WeatherSection(
            entry: entry,
            showWeather: $showWeather,
            currentWeather: $currentWeather
        )
    }

    // MARK: - Helper Methods
    private func calculateDistance(to entry: LocationEntry) -> CLLocationDistance? {
        guard let currentEntry = locationManager.currentEntry else { return nil }

        let savedCoordinate = CLLocation(latitude: entry.latitude, longitude: entry.longitude)
        let currentCoordinate = CLLocation(latitude: currentEntry.latitude, longitude: currentEntry.longitude)

        return savedCoordinate.distance(from: currentCoordinate)
    }

    private func deleteLocation() {
        if let entry = savedLocation.locationEntry {
            modelContext.delete(entry)
        }
        modelContext.delete(savedLocation)
        dismiss()
    }
}

// MARK: - Supporting Views
extension LocationDetailView {

    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()  // This line was causing the error
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(Theme.Colors.accent)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    EditButton()
                    DeleteButton()
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
    }

    @ViewBuilder
    private func DeleteConfirmationActions() -> some View {
        Button("Delete", role: .destructive) { deleteLocation() }
        Button("Cancel", role: .cancel) { }
    }

    private func EditButton() -> some View {
        NavigationLink {
            EditLocationView(location: savedLocation)
        } label: {
            Label("Edit Location", systemImage: "pencil")
        }
    }

    private func DeleteButton() -> some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            Label("Delete Location", systemImage: "trash")
        }
    }
}

// MARK: - Action Buttons
extension LocationDetailView {
    struct ActionButtons: View {
        let entry: LocationEntry
        let isDirectionsAvailable: Bool
        let onShare: () -> Void
        let onDirections: () -> Void

        var body: some View {
            HStack(spacing: Theme.Dimensions.padding) {
                ShareButton()
                DirectionsButton()
            }
            .padding(.horizontal, Theme.Dimensions.padding)
        }

        private func ShareButton() -> some View {
            Button(action: onShare) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .frame(height: Theme.Dimensions.buttonHeight)
            .foregroundStyle(Theme.Colors.buttonText)
            .background(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadius)
                    .fill(Theme.Colors.accent)
            )
        }

        private func DirectionsButton() -> some View {
            Button(action: onDirections) {
                if !isDirectionsAvailable {
                    Label("At Location", systemImage: "map")
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Directions", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: Theme.Dimensions.buttonHeight)
            .foregroundStyle(isDirectionsAvailable ? Theme.Colors.buttonText : .secondary)
            .background(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadius)
                    .fill(isDirectionsAvailable ? Theme.Colors.accent : Theme.Colors.subtle)
            )
            .disabled(!isDirectionsAvailable)
            .opacity(isDirectionsAvailable ? 1.0 : 0.5)
        }
    }
}

// MARK: - Sharing
extension LocationDetailView {

    func shareLocation(entry: LocationEntry) {
        let coordinates = "\(entry.latitude),\(entry.longitude)"
        let mapUrl = URL(string: "https://maps.apple.com/?q=\(coordinates)")!

        var shareText = "📍 \(savedLocation.locationDescription.isEmpty ? (entry.street ?? "Location") : savedLocation.locationDescription)"
        shareText += "\n\nOpen in Maps: \(mapUrl.absoluteString)"

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if UIDevice.current.userInterfaceIdiom == .pad {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(
                x: rootVC.view.bounds.midX,
                y: rootVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            activityVC.popoverPresentationController?.permittedArrowDirections = []
        }

        rootVC.present(activityVC, animated: true)
    }

    func openInMaps(entry: LocationEntry) {
        let coordinate = CLLocationCoordinate2D(
            latitude: entry.latitude,
            longitude: entry.longitude
        )
        let locationName = savedLocation.locationDescription.isEmpty ?
                          (savedLocation.locationEntry?.street ?? "Location") :
                          savedLocation.locationDescription

        // Get selected route planner from UserDefaults
        let routePlanner = UserDefaults.standard.string(forKey: "selectedRoutePlanner") ?? RoutePlanner.apple.rawValue

        switch routePlanner {
        case RoutePlanner.google.rawValue:
            // Google Maps URL scheme
            let urlString = "comgooglemaps://?q=\(coordinate.latitude),\(coordinate.longitude)&name=\(locationName)"
            if let encodedName = locationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: urlString.replacingOccurrences(of: locationName, with: encodedName)),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if !success {
                        print("Failed to open Google Maps")
                        self.fallbackToAppleMaps(coordinate: coordinate, name: locationName)
                    }
                }
            } else {
                fallbackToAppleMaps(coordinate: coordinate, name: locationName)
            }

        case RoutePlanner.waze.rawValue:
            // Waze URL scheme
            let urlString = "waze://?ll=\(coordinate.latitude),\(coordinate.longitude)&navigate=yes"
            if let url = URL(string: urlString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if !success {
                        print("Failed to open Waze")
                        self.fallbackToAppleMaps(coordinate: coordinate, name: locationName)
                    }
                }
            } else {
                fallbackToAppleMaps(coordinate: coordinate, name: locationName)
            }

        default:
            // Apple Maps (default case)
            fallbackToAppleMaps(coordinate: coordinate, name: locationName)
        }
    }

    private func fallbackToAppleMaps(coordinate: CLLocationCoordinate2D, name: String) {
        // Create a direct Apple Maps URL with directions
        let destinationCoordinate = "\(coordinate.latitude),\(coordinate.longitude)"
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // Build URL with directions mode
        let urlString = "maps://?daddr=\(destinationCoordinate)&dirflg=d&t=m"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    print("Failed to open Apple Maps with directions")
                    // Try simple coordinate-based URL as last resort
                    if let fallbackUrl = URL(string: "maps://?q=\(destinationCoordinate)&name=\(encodedName)") {
                        UIApplication.shared.open(fallbackUrl, options: [:]) { success in
                            if !success {
                                print("Failed to open Apple Maps with coordinates")
                            }
                        }
                    }
                }
            }
        }
    }

}

// MARK: - ButtonStyle for better touch feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
