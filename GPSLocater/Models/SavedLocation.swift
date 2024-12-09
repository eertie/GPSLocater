// Models/Location/SavedLocation.swift
import SwiftData
import CoreLocation

@Model
final class SavedLocation {
    var id: UUID
    var name: String
    var locationDescription: String
    var locationEntryId: UUID
    var createdAt: Date
    var isFavorite: Bool
   
    @Relationship(deleteRule: .cascade) var locationEntry: LocationEntry?
   
    init(name: String,
         locationDescription: String,
         locationEntry: LocationEntry,
         isFavorite: Bool = false) {
        self.id = UUID()
        self.name = name
        self.locationDescription = locationDescription
        self.locationEntryId = locationEntry.id
        self.locationEntry = locationEntry
        self.createdAt = Date()
        self.isFavorite = isFavorite
    }
}

extension SavedLocation: Hashable {
    static func == (lhs: SavedLocation, rhs: SavedLocation) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
