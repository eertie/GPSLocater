//  Utils/ModelUtils.swift
import CoreLocation
import SwiftData

func logSavedLocations(context: ModelContext, modelName:String="SavedLocation") {
    
    do {
        if modelName == "SavedLocation" {
            let descriptor = FetchDescriptor<SavedLocation>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            let locations = try context.fetch(descriptor)
            
            print("\n📍 Saved Locations (\(locations.count) total):")
            print("=====================================")
            
            for (index, location) in locations.enumerated() {
                print("\n🔸 Location #\(index + 1)")
                print("ID: \(location.id)")
                print("Description: \(location.locationDescription)")
                print("Created: \(location.createdAt.formatted())")
                
                if let entry = location.locationEntry {
                    print("Street: \(entry.street ?? "N/A")")
                    print("Place: \(entry.place ?? "N/A")")
                    print("Coordinates: (\(entry.latitude), \(entry.longitude))")
                    print("timestamp: \(entry.timestamp)")
                    
                } else {
                    print("Location Entry: Missing")
                }
                print("-------------------------------------")
            }
        } else {
            let descriptor = FetchDescriptor<LocationEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            
            let locations = try context.fetch(descriptor)
            
            print("\n📍 Saved Locations (\(locations.count) total):")
            
            print("=====================================")
         
            
            for (index, location) in locations.enumerated() {
                print("\n🔸 Location #\(index + 1)")
                print("ID: \(location.id)")
                print("timestamp: \(location.timestamp)")
                print("Coordinates: (\(location.latitude), \(location.longitude))")
                print("Street: \(location.street ?? "N/A")")
                print("Place: \(location.place ?? "N/A")")
                print("-------------------------------------")
            }
            
        }
    } catch {
        print("❌ Error fetching locations: \(error.localizedDescription)")
    }
}


func printUserDefaults() {
    let dictionary = UserDefaults.standard.dictionaryRepresentation()
    let sortedKeys = dictionary.keys.sorted()
    
    print("\n=== UserDefaults Contents ===\n")
    
    for key in sortedKeys {
        let value = dictionary[key]
        print("🔑 \(key)")
        print("📝 \(String(describing: value))")
        print("------------------------")
    }
}
