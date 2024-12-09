import SwiftUI

struct LocationRow: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    var additionalItems: [IconTextPair]?
    
  
    let location: SavedLocation
    let showLatLon : Bool

    
    init(location: SavedLocation, showLatLon: Bool = false, additionalItems: [IconTextPair]? = nil) {
        self.location = location
        self.showLatLon = showLatLon
        self.additionalItems = additionalItems
    }
    
    var body: some View {
        
        HStack(alignment: .center, spacing: Theme.Dimensions.padding) {
            VStack(alignment: .leading, spacing: Theme.Dimensions.smallPadding) {
                
                
                if !location.locationDescription.isEmpty {
                    Text(location.locationDescription)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.primaryText)
                        .lineLimit(2)
                }
                
                if let entry = location.locationEntry {
                    LocationAddressView(entry: entry)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                
                if showLatLon {
                    CoordinatesView(
                        latitude: location.locationEntry!.latitude,
                        longitude: location.locationEntry!.longitude
                    ).font(Theme.Typography.caption)
                     .foregroundStyle(Theme.Colors.secondaryText)
                     .lineLimit(1)
                }
                
                HStack(spacing: Theme.Dimensions.smallPadding) {
                    Image(systemName: "calendar")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    
                    Text(location.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                
             
                // Additional items
                if let additionalItems = additionalItems {
                    ForEach(additionalItems, id: \.text) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.icon)
                                .foregroundColor(item.iconColor)
                                .font(.system(size: item.iconSize))
                            Text(item.text)
                                .foregroundStyle(Theme.Colors.secondaryText)
                                .font(Theme.Typography.caption)
                                //.foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack {
                Spacer()
                Image(systemName: location.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(
                        location.isFavorite ?
                        Theme.Colors.warning :
                            (themeManager.isDarkMode ? Theme.Colors.subtle : Theme.Colors.secondaryText)
                    )
                    .imageScale(.medium)
                Spacer()
            }
        }
        .padding(Theme.Dimensions.padding)
        .background(Theme.Colors.cardBackground)
        .padding(.horizontal, Theme.Dimensions.padding)
        .padding(.vertical, Theme.Dimensions.smallPadding)
    }
}
