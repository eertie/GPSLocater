import Foundation
import CoreLocation
import WeatherKit

// MARK: - Weather Data Models
struct WeatherData {
    let temperature: Double
    let condition: WeatherCondition
    let humidity: Double
    let windSpeed: Double
    let timestamp: Date
    
    enum WeatherCondition {
        case clear, cloudy, rain, snow, storm, mist, unknown
        
        var description: String {
            switch self {
            case .clear: return "Clear"
            case .cloudy: return "Cloudy"
            case .rain: return "Rain"
            case .snow: return "Snow"
            case .storm: return "Storm"
            case .mist: return "Misty"
            case .unknown: return "Unknown"
            }
        }
        
        var iconName: String {
            switch self {
            case .clear: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rain: return "cloud.rain.fill"
            case .snow: return "cloud.snow.fill"
            case .storm: return "cloud.bolt.fill"
            case .mist: return "cloud.fog.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }
}

// MARK: - Weather Error Types
enum WeatherError: LocalizedError {
    case authenticationFailed
    case serviceUnavailable
    case invalidLocation
    case networkError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Weather service authentication failed. Please try again later."
        case .serviceUnavailable:
            return "Weather service is currently unavailable. Please try again later."
        case .invalidLocation:
            return "Invalid location coordinates provided."
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .unknown(let error):
            return "Unexpected error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Weather Manager
@MainActor
class WeatherManager: NSObject, ObservableObject {
    // MARK: - Properties
    private let weatherService = WeatherService.shared
    @Published private(set) var currentWeather: WeatherData?
    @Published private(set) var error: WeatherError?
    @Published private(set) var isLoading = false
    
    private var requestsInProgress: Set<String> = []
    private let cache = NSCache<NSString, CachedWeatherData>()
    private let cacheTimeout: TimeInterval = 900 // 15 minutes
    private var isAuthenticated = false
    
    // MARK: - Initialization
    static let shared = WeatherManager()
    
    override private init() {
        super.init()
        cache.countLimit = 50
    }
    
    // MARK: - Authentication
    private func verifyWeatherKitAccess() async throws {
        guard !isAuthenticated else { return }
        
        do {
            let testLocation = CLLocation(latitude: 0, longitude: 0)
            _ = try await weatherService.weather(for: testLocation)
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            throw WeatherError.authenticationFailed
        }
    }
    
    // MARK: - Public Methods
    func fetchWeather(latitude: Double, longitude: Double) async -> WeatherData? {
        let locationKey = "\(latitude),\(longitude)"
        
        guard !requestsInProgress.contains(locationKey) else {
            return nil
        }
        
        if let cachedData = getCachedWeather(for: locationKey) {
            return cachedData
        }
        
        requestsInProgress.insert(locationKey)
        isLoading = true
        error = nil
        
        defer {
            requestsInProgress.remove(locationKey)
            isLoading = false
        }
        
        do {
            try await verifyWeatherKitAccess()
            
            guard CLLocationCoordinate2D(latitude: latitude, longitude: longitude).isValid else {
                throw WeatherError.invalidLocation
            }
            
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let weather = try await fetchWithRetry(location: location)
            
            let weatherData = WeatherData(
                temperature: weather.currentWeather.temperature.value,
                condition: mapCondition(weather.currentWeather.condition),
                humidity: weather.currentWeather.humidity,
                windSpeed: weather.currentWeather.wind.speed.value,
                timestamp: Date()
            )
            
            cacheWeather(weatherData, for: locationKey)
            currentWeather = weatherData
            error = nil
            return weatherData
            
        } catch {
            handleError(error)
            return nil
        }
    }
    
    // MARK: - Private Methods
    private func fetchWithRetry(location: CLLocation, attempts: Int = 3) async throws -> Weather {
        var lastError: Error?
        
        for attempt in 1...attempts {
            do {
                if attempt > 1 {
                    isAuthenticated = false
                    try await verifyWeatherKitAccess()
                }
                
                return try await weatherService.weather(for: location)
            } catch {
                lastError = error
                if attempt < attempts {
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * pow(2.0, Double(attempt))))
                }
            }
        }
        
        throw lastError ?? WeatherError.serviceUnavailable
    }
    
    private func mapCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherData.WeatherCondition {
        switch condition {
        case .clear, .mostlyClear, .hot:
            return .clear
        case .cloudy, .mostlyCloudy, .partlyCloudy:
            return .cloudy
        case .drizzle, .rain, .heavyRain, .sunShowers:
            return .rain
        case .snow, .heavySnow, .flurries, .sunFlurries, .sleet,
             .freezingDrizzle, .freezingRain, .wintryMix, .blowingSnow:
            return .snow
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms,
             .strongStorms, .hurricane, .tropicalStorm, .blizzard:
            return .storm
        case .foggy, .haze, .smoky, .breezy, .windy, .frigid, .blowingDust:
            return .mist
        case .hail:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    
    private func handleError(_ error: Error) {
        if let weatherError = error as? WeatherError {
            self.error = weatherError
        } else {
            let nsError = error as NSError
            if nsError.domain.contains("WeatherKit") ||
               nsError.domain.contains("WeatherDaemon") {
                recoverFromAuthError()
                self.error = .authenticationFailed
            } else if nsError.domain == NSURLErrorDomain {
                self.error = .networkError
            } else {
                self.error = .unknown(error)
            }
        }
        print("Weather error: \(error.localizedDescription)")
    }
    
    private func recoverFromAuthError() {
        isAuthenticated = false
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Caching Support
private class CachedWeatherData {
    let weatherData: WeatherData
    let timestamp: Date
    
    init(weatherData: WeatherData, timestamp: Date) {
        self.weatherData = weatherData
        self.timestamp = timestamp
    }
}

private extension WeatherManager {
    func getCachedWeather(for key: String) -> WeatherData? {
        guard let cached = cache.object(forKey: key as NSString) else {
            return nil
        }
        
        if Date().timeIntervalSince(cached.timestamp) > cacheTimeout {
            cache.removeObject(forKey: key as NSString)
            return nil
        }
        
        return cached.weatherData
    }
    
    func cacheWeather(_ weather: WeatherData, for key: String) {
        let cached = CachedWeatherData(weatherData: weather, timestamp: Date())
        cache.setObject(cached, forKey: key as NSString)
    }
}

// MARK: - Coordinate Validation
private extension CLLocationCoordinate2D {
    var isValid: Bool {
        latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
    }
}
