import SwiftUI
import MapKit

struct IconTextPair {
    let icon: String
    let text: String
    let iconColor: Color
    let iconSize: CGFloat
    
    init(icon: String, text: String, color: Color = .secondary, size: CGFloat = 16) {
        self.icon = icon
        self.text = text
        self.iconColor = color
        self.iconSize = size
    }
}


func formatDistance(_ distance: CLLocationDistance) -> String {
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
