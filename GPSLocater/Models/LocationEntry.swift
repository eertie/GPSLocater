// Models/Location/LocationEntry.swift
import SwiftData
import Foundation

@Model
final class LocationEntry {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var street: String?
    var place: String?
    
    @Relationship(inverse: \SavedLocation.locationEntry) var savedLocation: SavedLocation?

    init(id: UUID = UUID(),
         latitude: Double,
         longitude: Double,
         timestamp: Date = Date(),
         street: String? = nil,
         place: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.street = street
        self.place = place
    }
}
