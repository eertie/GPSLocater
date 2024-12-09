import SwiftUI
import MapKit

struct MapSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var locationManager: LocationManager
    @Binding var showMap: Bool
    @Binding var selectedMapType: MKMapType
    
    let entry: LocationEntry
    let region: MKCoordinateRegion
    
    init(showMap: Binding<Bool>,
         selectedMapType: Binding<MKMapType>,
         entry: LocationEntry,
         region: MKCoordinateRegion) {
        self._showMap = showMap
        self._selectedMapType = selectedMapType
        self.entry = entry
        self.region = region
    }
    
    var body: some View {
        VStack() {
            //            MapButton()
            
            if showMap {
                MapCard()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    
    private func MapButton() -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showMap.toggle()
            }
        }) {
            HStack {
                Label("Location Map", systemImage: "map.fill")
                Spacer()
                Image(systemName: showMap ? "chevron.up.circle.fill" : "chevron.right.circle.fill")
            }
            
            .frame(height: Theme.Dimensions.buttonHeight)
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            .padding(.horizontal, Theme.Dimensions.padding) // Inner padding
            .foregroundStyle(Theme.Colors.buttonText)
            .background(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadius)
                    .fill(Theme.Colors.accent)
            )
            
            .padding(.horizontal, Theme.Dimensions.padding) // Outer padding
            .padding(.vertical, Theme.Dimensions.smallPadding)
        }
    }
    
    private func MapCard() -> some View {
        let region = calculateRegionForBothLocations()
        
        return Map(position: .constant(MapCameraPosition.region(region))) {
            
            Annotation(
                entry.street ?? "Location",
                coordinate: CLLocationCoordinate2D(
                    latitude: entry.latitude,
                    longitude: entry.longitude
                ),
                anchor: .bottom
            ) {
                VStack(spacing: 0) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                    
//                    Text(entry.street ?? "Location")
//                        .font(.caption)
//                        .padding(4)
//                        .background(
//                            RoundedRectangle(cornerRadius: 4)
//                                .fill(Theme.Colors.cardBackground.opacity(0.9))
//                        )
                }
            }
                       
            
            // Current location
            if let currentEntry = locationManager.currentEntry {
                Marker(
                    currentEntry.street ?? "Current Location",
                    coordinate: CLLocationCoordinate2D(
                        latitude: currentEntry.latitude,
                        longitude: currentEntry.longitude
                    )
                )
                .tint(Theme.Colors.accent)
            }
            
            
        }
        .frame(minHeight: 300, maxHeight: .infinity)
        .mapStyle(selectedMapType == .standard ? .standard : .hybrid)
        .mapControls {
            MapScaleView()
        }
        .overlay(
            MapTypeButton(selectedMapType: $selectedMapType)
                .padding(8),
            alignment: .topTrailing
        )
    }
    
    // function to calculate the region that includes both points
    private func calculateRegionForBothLocations() -> MKCoordinateRegion {
        guard let currentLocation = locationManager.currentEntry else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: entry.latitude,
                    longitude: entry.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
        
        // Create a rectangle that contains both points
        let points = [
            CLLocationCoordinate2D(latitude: entry.latitude, longitude: entry.longitude),
            CLLocationCoordinate2D(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        ]
        
        var minLat = Double.infinity
        var maxLat = -Double.infinity
        var minLon = Double.infinity
        var maxLon = -Double.infinity
        
        // Find the bounding box
        for point in points {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }
        
        // Calculate center
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Calculate span with padding
        let latDelta = (maxLat - minLat) * 1.5 // 1.5 adds 50% padding
        let lonDelta = (maxLon - minLon) * 1.5
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: centerLat,
                longitude: centerLon
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01), // Minimum zoom level
                longitudeDelta: max(lonDelta, 0.01)
            )
        )
    }
}

// MARK: - Location Annotation View
struct LocationAnnotationView: View {
    let entry: LocationEntry
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundStyle(.red)
                .background(Circle().fill(.white))
            
            VStack(spacing: 2) {
                if let street = entry.street {
                    Text(street)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .truncationMode(.tail)
                }
            }
            .font(.caption)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 2)
            )
            .foregroundStyle(.primary)
        }
    }
}

struct MapTypeButton: View {
    @Binding var selectedMapType: MKMapType
    
    var body: some View {
        Button {
            withAnimation {
                selectedMapType = selectedMapType == .standard ? .hybrid : .standard
            }
        } label: {
            Image(systemName: selectedMapType == .standard ? "map" : "map.fill")
                .font(.system(size: 16)) // Added consistent size
                .frame(width: 32, height: 32) // Added fixed frame
                .foregroundStyle(Theme.Colors.accent) // Added accent color
                .background(Theme.Colors.cardBackground)
                .clipShape(Circle())
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
                .padding(.horizontal, Theme.Dimensions.padding) // Added horizontal padding
                .padding(.vertical, Theme.Dimensions.smallPadding) // Added vertical padding
        }
    }
}

