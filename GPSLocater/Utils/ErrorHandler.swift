import Foundation
import CoreLocation
import AVFoundation

// Add this at the top of the file
var isDebugMode: Bool {
    UserDefaults.standard.bool(forKey: "DEBUG_MODE")
}

// MARK: - Error Types
enum SystemPermissionError: Error {
    case cameraAccessDenied
    case microphoneAccessDenied
    case photoLibraryAccessDenied
    case contactsAccessDenied
    case notificationsDisabled
    case bluetoothDisabled
    case networkUnavailable
    case biometricsUnavailable
    case unknown(Error)
}

// MARK: - Error Extensions
extension Error {
    var userFriendlyMessage: String {
        switch self {
        case let locationError as LocationError:
            return locationError.userFriendlyMessage
        case let permissionError as SystemPermissionError:
            return permissionError.userFriendlyMessage
        case let avError as AVError:
            return handleAVError(avError)
        case let clError as CLError:
            return handleCLError(clError)
        case let nsError as NSError:
            return handleNSError(nsError)
        default:
            if isDebugMode {
                return self.localizedDescription
            } else {
                return "Something went wrong. Please try again later."
            }
        }
    }
}

extension LocationError {
    var userFriendlyMessage: String {
        switch self {
        case .servicesDisabled:
            return "Location services are disabled. Please enable them in Settings."
        case .denied:
            return "Location access was denied. Please allow access in Settings."
        case .unknown(let error):
            if isDebugMode {
                return error.localizedDescription
            } else {
                return "Unable to access location services. Please try again."
            }
        case .locationUnavailable:
            return "Unable to update location. Please try again."
        }
    }
}

extension SystemPermissionError {
    var userFriendlyMessage: String {
        switch self {
        case .cameraAccessDenied:
            return "Camera access is required but was denied. Please enable it in Settings."
        case .microphoneAccessDenied:
            return "Microphone access is required but was denied. Please enable it in Settings."
        case .photoLibraryAccessDenied:
            return "Photo library access is required but was denied. Please enable it in Settings."
        case .contactsAccessDenied:
            return "Contacts access is required but was denied. Please enable it in Settings."
        case .notificationsDisabled:
            return "Notifications are disabled. Please enable them in Settings to receive updates."
        case .bluetoothDisabled:
            return "Bluetooth is required but disabled. Please enable it in Settings."
        case .networkUnavailable:
            return "Network connection unavailable. Please check your internet connection."
        case .biometricsUnavailable:
            return "Biometric authentication is not available on this device."
        case .unknown(let error):
            if isDebugMode {
                return error.localizedDescription
            } else {
                return "An unexpected error occurred. Please try again."
            }
        }
    }
}

// MARK: - Private Error Handlers
private func handleAVError(_ error: AVError) -> String {
    if isDebugMode {
        return error.localizedDescription  // Changed from self to error
    } else {
  
        switch error.code {
        case .deviceNotConnected:
            return "Required device is not connected."
        case .mediaServicesWereReset:
            return "Media services need to be restarted. Please try again."
        case .diskFull:
            return "Not enough storage space available."
        case .applicationIsNotAuthorized:
            return "Access to media services was denied."
        case .contentIsUnavailable:
            return "The media format is not supported."
        case .noDataCaptured:
            return "No media data was captured."
        case .operationNotAllowed:
            return "This operation is not allowed."
        case .deviceAlreadyUsedByAnotherSession:
            return "The device is being used by another application."
        default:
            return "Media error occurred. Please try again."
        }
    }
}

private func handleCLError(_ error: CLError) -> String {
    if isDebugMode {
        return error.localizedDescription
    } else {
        switch error.code {
        case .denied:
            return "Location access was denied. Please allow access in Settings."
        case .locationUnknown:
            return "Unable to determine your location. Please try again."
        case .network:
            return "Network error. Please check your connection and try again."
        case .headingFailure:
            return "Unable to determine device heading. Please try again."
        case .rangingUnavailable:
            return "Ranging is not available at this time."
        case .rangingFailure:
            return "Unable to determine range information."
        case .promptDeclined:
            return "Location access prompt was declined."
        case .regionMonitoringDenied:
            return "Region monitoring access was denied."
        case .regionMonitoringFailure:
            return "Region monitoring is not available."
        case .regionMonitoringSetupDelayed:
            return "Region monitoring setup was delayed."
        case .regionMonitoringResponseDelayed:
            return "Region monitoring response was delayed."
        case .geocodeFoundNoResult:
            return "No matching locations were found."
        case .geocodeFoundPartialResult:
            return "Only partial location results were found."
        case .geocodeCanceled:
            return "Location search was canceled."
        case .deferredFailed:
            return "Location update failed."
        case .deferredNotUpdatingLocation:
            return "Location updates are not active."
        case .deferredAccuracyTooLow:
            return "Location accuracy is too low."
        case .deferredDistanceFiltered:
            return "Location update was filtered due to distance."
        case .deferredCanceled:
            return "Location update was canceled."
        case .historicalLocationError:
            return "Unable to retrieve historical location data."
        @unknown default:
            return "Unable to access location services. Please try again."
        }
    }
}


private func handleNSError(_ error: NSError) -> String {
    if isDebugMode {
        return error.localizedDescription
    } else {
        switch error.domain {
        case kCLErrorDomain:
            if let clError = CLError.Code(rawValue: error.code) {
                return handleCLError(CLError(clError))
            }
            return "Unable to access location services. Please try again."
        default:
            return "Something went wrong. Please try again later."
        }
    }
}

// MARK: - Test Cases Extension
extension TestCase {
    static var systemPermissionErrors: [TestCase] = [
        TestCase(title: "Camera Access Denied", error: SystemPermissionError.cameraAccessDenied),
        TestCase(title: "Microphone Access Denied", error: SystemPermissionError.microphoneAccessDenied),
        TestCase(title: "Photo Library Access Denied", error: SystemPermissionError.photoLibraryAccessDenied),
        TestCase(title: "Contacts Access Denied", error: SystemPermissionError.contactsAccessDenied),
        TestCase(title: "Notifications Disabled", error: SystemPermissionError.notificationsDisabled),
        TestCase(title: "Bluetooth Disabled", error: SystemPermissionError.bluetoothDisabled),
        TestCase(title: "Network Unavailable", error: SystemPermissionError.networkUnavailable),
        TestCase(title: "Biometrics Unavailable", error: SystemPermissionError.biometricsUnavailable)
    ]
    
    static var mediaErrors: [TestCase] = [
        TestCase(title: "Device Not Connected", error: AVError(.deviceNotConnected)),
        TestCase(title: "Media Services Reset", error: AVError(.mediaServicesWereReset)),
        TestCase(title: "Storage Full", error: AVError(.diskFull)),
        TestCase(title: "Media Access Denied", error: AVError(.applicationIsNotAuthorized)),
        TestCase(title: "Invalid Media Data", error: AVError(.contentIsUnavailable)),
        TestCase(title: "No Data Captured", error: AVError(.noDataCaptured)),
        TestCase(title: "Operation Not Allowed", error: AVError(.operationNotAllowed)),
        TestCase(title: "Device In Use", error: AVError(.deviceAlreadyUsedByAnotherSession))
    ]
}
