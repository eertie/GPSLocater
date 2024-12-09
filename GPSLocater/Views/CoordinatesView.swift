import SwiftUI
import CoreLocation

struct CoordinatesView: View {
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    
    var body: some View {
        HStack(spacing: Theme.Dimensions.padding) {
            Image(systemName: "location.fill")
                .foregroundStyle(Theme.Colors.accent)
//                .frame(width: 20)
            
            HStack() {
                Text("Lat: \(formatCoordinate(latitude))")
                Text("Lon: \(formatCoordinate(longitude))")
            }
//           .foregroundStyle(Theme.Colors.primaryText)
//            .font(.system(.caption, design: .monospaced))
        }
        .toolbarBackground(Theme.Colors.primaryBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    private func formatCoordinate(_ coordinate: CLLocationDegrees) -> String {
        String(format: "%.6f°", coordinate)
    }
}


#Preview {
    CoordinatesView(latitude: 37.7749, longitude: -122.4194)
        .padding()
        .background(Theme.Colors.cardBackground)
}
