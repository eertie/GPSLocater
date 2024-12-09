// Create a new file called ErrorHandlingTests.swift

import SwiftUI
import CoreLocation

struct ErrorHandlingTestView: View {
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            Section("System Permission Errors") {
                ForEach(TestCase.systemPermissionErrors, id: \.title) { testCase in
                    ErrorTestRow(testCase: testCase) { error in
                        alertMessage = error.userFriendlyMessage
                        showingAlert = true
                    }
                }
            }
            
            Section("Media Errors") {
                ForEach(TestCase.mediaErrors, id: \.title) { testCase in
                    ErrorTestRow(testCase: testCase) { error in
                        alertMessage = error.userFriendlyMessage
                        showingAlert = true
                    }
                }
            }
            
            Section("Location Errors") {
                ForEach(TestCase.locationErrors, id: \.title) { testCase in
                    ErrorTestRow(testCase: testCase) { error in
                        alertMessage = error.userFriendlyMessage
                        showingAlert = true
                    }
                }
            }
            
            Section("CLError Cases") {
                ForEach(TestCase.clErrors, id: \.title) { testCase in
                    ErrorTestRow(testCase: testCase) { error in
                        alertMessage = error.userFriendlyMessage
                        showingAlert = true
                    }
                }
            }
            
            Section("NSError Cases") {
                ForEach(TestCase.nsErrors, id: \.title) { testCase in
                    ErrorTestRow(testCase: testCase) { error in
                        alertMessage = error.userFriendlyMessage
                        showingAlert = true
                    }
                }
            }
        }
        .navigationTitle("Error Handling Tests")
        .alert("Error Message", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}
struct ErrorTestRow: View {
    let testCase: TestCase
    let onTest: (Error) -> Void
    
    var body: some View {
        Button {
            onTest(testCase.error)
        } label: {
            HStack {
                Text(testCase.title)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct TestCase {
    let title: String
    let error: Error
    
    static var locationErrors: [TestCase] = [
        TestCase(title: "Services Disabled", error: LocationError.servicesDisabled),
        TestCase(title: "Access Denied", error: LocationError.denied),
        TestCase(title: "Unknown Error", error: LocationError.unknown(NSError(domain: "TestDomain", code: -1)))
    ]
    
    static var clErrors: [TestCase] = [
        TestCase(title: "Location Unknown", error: CLError(.locationUnknown)),
        TestCase(title: "Denied", error: CLError(.denied)),
        TestCase(title: "Network Error", error: CLError(.network)),
        TestCase(title: "Heading Failure", error: CLError(.headingFailure)),
        TestCase(title: "Ranging Unavailable", error: CLError(.rangingUnavailable)),
        TestCase(title: "Prompt Declined", error: CLError(.promptDeclined)),
        TestCase(title: "Region Monitoring Denied", error: CLError(.regionMonitoringDenied))
    ]
    
    static var nsErrors: [TestCase] = [
        TestCase(title: "Generic NSError", error: NSError(domain: "com.test", code: -1)),
        TestCase(title: "CLError as NSError", error: NSError(domain: kCLErrorDomain, code: CLError.denied.rawValue)),
        TestCase(title: "Custom Domain Error", error: NSError(domain: "CustomDomain", code: 404))
    ]
}

#Preview {
    NavigationStack {
        ErrorHandlingTestView()
    }
}
