import CoreLocation
import SwiftData

@MainActor
final class LocationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var currentStreet: String?
    @Published private(set) var currentPlace: String?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published var currentEntry: LocationEntry?
    
    static let shared = LocationManager()
    
    // MARK: - Private Properties
    private let locationManager: CLLocationManager
    private let geocoder = CLGeocoder()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authorizationContinuation: CheckedContinuation<CLLocation, Error>?
    
    // MARK: - Initialization
    override init() {
        locationManager = CLLocationManager()
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Public Methods
    func getCurrentLocation() async throws -> CLLocation {
        // Reset current state
        await resetState()
        
        // Wait for and check authorization status
        return try await withCheckedThrowingContinuation { continuation in
            authorizationContinuation = continuation
            
            // Check current status
            let status = locationManager.authorizationStatus
            switch status {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                Task {
                    do {
                        let location = try await getLocationUpdate()
                        continuation.resume(returning: location)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            case .denied, .restricted:
                continuation.resume(throwing: LocationError.denied)
            @unknown default:
                continuation.resume(throwing: LocationError.unknown(NSError(domain: "LocationManager", code: -1)))
            }
        }
    }
    
    func oldgetCurrentLocation() async throws -> CLLocation {
        // First check if location services are enabled
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationError.servicesDisabled
        }
        
        // Reset current state
        await resetState()
        
        // Handle authorization if needed
        if locationManager.authorizationStatus == .notDetermined {
            return try await withCheckedThrowingContinuation { continuation in
                authorizationContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }
        }
        
        // If already authorized, get location directly
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return try await getLocationUpdate()
        case .denied, .restricted:
            throw LocationError.denied
        case .notDetermined:
            throw LocationError.unknown(NSError(domain: "LocationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authorization status remained undetermined"]))
        @unknown default:
            throw LocationError.unknown(NSError(domain: "LocationManager", code: -1))
        }
    }
    

    // MARK: - Private Methods
    private func resetState() async {
        currentLocation = nil
        currentEntry = nil
        currentStreet = nil
        currentPlace = nil
    }
    
    private func requestAuthorization() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            authorizationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func getLocationUpdate() async throws -> CLLocation {
        let location = try await withTimeout(seconds: 15) { [self] in
            try await withCheckedThrowingContinuation { continuation in
                locationContinuation = continuation
                locationManager.requestLocation()
            }
        }
        
        await updateLocationInfo(location)
        return location
    }
    
    private func updateLocationInfo(_ location: CLLocation) async {
        currentLocation = location
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                currentStreet = placemark.thoroughfare
                currentPlace = [placemark.locality, placemark.administrativeArea]
                    .compactMap { $0 }
                    .joined(separator: ", ")
            }
            
            currentEntry = LocationEntry(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                street: currentStreet,
                place: currentPlace
            )
        } catch {
            print("Geocoding error: \(error.localizedDescription)")
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw LocationError.unknown(NSError(
                    domain: "LocationManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Location request timed out"]
                ))
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    func getCurrentLocationSync() throws -> LocationEntry {
        guard let currentEntry = currentEntry else {
            throw LocationError.locationUnavailable
        }
        return currentEntry
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if let continuation = authorizationContinuation {
                    do {
                        let location = try await getLocationUpdate()
                        continuation.resume(returning: location)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                    authorizationContinuation = nil
                }
            case .denied, .restricted:
                authorizationContinuation?.resume(throwing: LocationError.denied)
                authorizationContinuation = nil
            case .notDetermined:
                break
            @unknown default:
                authorizationContinuation?.resume(throwing: LocationError.unknown(NSError(domain: "LocationManager", code: -1)))
                authorizationContinuation = nil
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
    }
}

// MARK: - LocationError
enum LocationError: LocalizedError {
    case servicesDisabled
    case denied
    case unknown(Error)
    case locationUnavailable
    
    var errorDescription: String? {
        switch self {
        case .servicesDisabled:
            return "Location services are disabled"
        case .denied:
            return "Location access was denied"
        case .locationUnavailable:
            return "Location is unavailable"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}


// Add this extension for convenience
extension ModelContext {
    func refreshAll() {
        print("REFRESHIN... >>>")
        try? fetch(FetchDescriptor<SavedLocation>())
//        try? fetch(FetchDescriptor<LocationEntry>())
    }
}
