import SwiftUI
import CoreLocation

struct CurrentLocationView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject private var locationManager: LocationManager
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    var body: some View {
        locationContent
            .padding(.horizontal, Theme.Dimensions.padding)
            .tint(Theme.Colors.accent)
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
    
    private var locationContent: some View {
        VStack(alignment: .leading, spacing: Theme.Dimensions.smallPadding) {
            Group {
                if let location = locationManager.currentLocation {
                    locationDetailsView(for: location)
                } else {
                    loadingView
                }
            }
        }
    }
    
    private func locationDetailsView(for location: CLLocation) -> some View {
        Group {
            if let street = locationManager.currentStreet {
                locationRow(icon: "mappin.circle.fill", text: street)
            }
            
            if let place = locationManager.currentPlace {
                locationRow(icon: "building.2.fill", text: place)
            }
            
            CoordinatesView(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            .font(Theme.Typography.subheadline)
            .foregroundStyle(Theme.Colors.primaryText)
        }
    }
    
    private func locationRow(icon: String, text: String) -> some View {
        HStack(spacing: Theme.Dimensions.smallPadding) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Colors.accent)
            Text(text)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.primaryText)
                .lineLimit(1)
        }
    }
    
    private var loadingView: some View {
        locationRow(icon: "location.circle", text: "Acquiring location...")
            .foregroundStyle(Theme.Colors.secondaryText)
    }
}
