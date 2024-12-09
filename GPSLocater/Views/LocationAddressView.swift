//
// Views/LocationAddressView.swift

import SwiftUI
import MapKit
import SwiftData

struct LocationAddressView: View {
    let entry: LocationEntry
    var additionalItems: [IconTextPair]?
    
    init(entry: LocationEntry, additionalItems: [IconTextPair]? = nil) {
        self.entry = entry
        self.additionalItems = additionalItems
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // Street info
                if let street = entry.street {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                        Text(street)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Place info
                if let place = entry.place {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.indigo)
                            .font(.system(size: 16))
                        Text(place)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Additional items
                if let additionalItems = additionalItems {
                    ForEach(additionalItems, id: \.text) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.icon)
                                .foregroundColor(item.iconColor)
                                .font(.system(size: item.iconSize))
                            Text(item.text)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            Spacer()
        }
    }
}

// Usage example:
#Preview {
    let entry = LocationEntry(latitude: 0, longitude: 0)
    return LocationAddressView(
        entry: entry,
        additionalItems: [
            IconTextPair(
                icon: "calendar",
                text: Date().formatted(date: .long, time: .shortened)
            )
        ]
    )
}
