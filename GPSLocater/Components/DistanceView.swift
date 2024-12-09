import SwiftUI
import MapKit

struct DistanceView: View {
    let distance: CLLocationDistance
    let savedLocation: SavedLocation
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .foregroundStyle(Theme.Colors.accent)
            
            (Text("Distance to: ")
              + Text(savedLocation.locationEntry?.street ?? "location")
//             + Text(!savedLocation.locationDescription.isEmpty
//                   ? savedLocation.locationDescription
//                   : savedLocation.locationEntry?.street ?? "location")
             + Text(": ")
             + Text(formatDistance(distance))
                .bold()
            )
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Colors.secondaryText)
            .lineLimit(1)
            .truncationMode(.middle)
            
            Spacer()
        }
        .padding(.horizontal)        
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 0
        
        let measurement: Measurement<UnitLength>
        if distance >= 1000 {
            measurement = Measurement(value: distance / 1000, unit: UnitLength.kilometers)
        } else {
            measurement = Measurement(value: distance, unit: UnitLength.meters)
        }
        
        return formatter.string(from: measurement)
    }
}
