import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers
import Foundation

enum RoutePlanner: String, CaseIterable {
    case apple = "Apple Maps"
    case google = "Google Maps"
    case waze = "Waze"

    var iconName: String {
        switch self {
        case .apple: return "map.fill"
        case .google: return "map"
        case .waze: return "location.fill"
        }
    }

    var isInstalled: Bool {
        switch self {
        case .apple:
            return true // Apple Maps is always installed
        case .google:
            guard let url = URL(string: "comgooglemaps://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        case .waze:
            guard let url = URL(string: "waze://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }
}

struct DeleteFeedbackToast: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let message: String
    let isError: Bool

    var body: some View {
        HStack {
            Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
            Text(message)
        }
        .padding()
        .background(isError ? Theme.Colors.error.opacity(0.9) : Theme.Colors.success.opacity(0.9))
        .foregroundStyle(Theme.Colors.buttonText)
        .clipShape(Capsule())
        .shadow(radius: 10)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    @State private var isFeedbackError = false
    @State private var selectedTheme: ThemeColor
    @AppStorage("selectedRoutePlanner") private var selectedRoutePlanner: RoutePlanner = .apple
    @State private var isExporting = false
    @State private var exportFileURL: URL?
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showImportError = false

    init() {
        _selectedTheme = State(initialValue: ThemeManager.shared.current)
    }

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                navigationSection
                dataSection
//                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    closeButton
//                }
//            }
            .confirmationDialog(
                "Delete All Locations",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    Task { await deleteAllLocations() }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. Are you sure you want to delete all saved locations?")
            }
            .overlay(alignment: .top) {
                if showFeedback {
                    DeleteFeedbackToast(message: feedbackMessage, isError: isFeedbackError)
                        .transition(.move(edge: .top))
                        .padding(.top, 10)
                }
            }
            .animation(.spring(), value: showFeedback)
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }

    private var appearanceSection: some View {
        Section {

            // Theme Selection
            DisclosureGroup(
                content: {
                    VStack(spacing: 0) {
                        ForEach(ThemeColor.allCases, id: \.self) { theme in
                            ThemeSelectionRow(
                                theme: theme,
                                isSelected: selectedTheme == theme,
                                action: {
                                    withAnimation {
                                        selectedTheme = theme
                                        themeManager.setTheme(theme)
                                    }
                                }
                            )

                            if theme != ThemeColor.allCases.last {
                                Divider()
                            }
                        }
                    }
                },
                label: {
                    HStack {
                        ThemePreviewCircle(theme: selectedTheme)
                            .frame(width: 20, height: 20)
                        Text("Theme: \(selectedTheme.displayName)")
                            .foregroundStyle(Theme.Colors.primaryText)
                    }
                }
            )
            .tint(Theme.Colors.primaryText)

            // Dark Mode Toggle
            Toggle(isOn: $themeManager.isDarkMode) {
                HStack(spacing: Theme.Dimensions.smallPadding) {
                    Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                    Text("Dark Mode")
                        .foregroundStyle(Theme.Colors.primaryText)
                }
            }
            .onChange(of: themeManager.isDarkMode) { _, newValue in
                withAnimation {
                    setAppearance(newValue)
                }
            }


        } header: {
            Text("Appearance")
                .foregroundStyle(Theme.Colors.secondaryText)
        }
    }

    private var navigationSection: some View {
        Section {
            DisclosureGroup(
                content: {
                    VStack(spacing: 0) {
                        ForEach(RoutePlanner.allCases.filter(\.isInstalled), id: \.self) { planner in
                            Button(action: {
                                withAnimation {
                                    selectedRoutePlanner = planner
                                }
                            }) {
                                HStack {
                                    Image(systemName: planner.iconName)
                                        .frame(width: 24, height: 24)
                                    Text(planner.rawValue)
                                        .foregroundStyle(Theme.Colors.primaryText)
                                    Spacer()
                                    if selectedRoutePlanner == planner {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.Colors.accent)
                                    }
                                }
                                .contentShape(Rectangle())
                                .frame(minHeight: 44) // Following Apple's minimum touch target size
                            }
                            .buttonStyle(.plain)

                            if planner != RoutePlanner.allCases.filter(\.isInstalled).last {
                                Divider()
                            }
                        }
                    }
                },
                label: {
                    HStack {
                        Image(systemName: selectedRoutePlanner.iconName)
                            .frame(width: 20, height: 20)
                        Text("Default Navigation: \(selectedRoutePlanner.rawValue)")
                            .foregroundStyle(Theme.Colors.primaryText)
                    }
                }
            )
            .tint(Theme.Colors.primaryText)
        } header: {
            Text("Navigation")
                .foregroundStyle(Theme.Colors.secondaryText)
        }
    }

    private var dataSection: some View {
        Section {
            // Export button
            Button {
                exportLocations()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Locations")

                    if isExporting {
                        Spacer()
                        ProgressView()
                            .tint(Theme.Colors.accent)
                    }
                }
                .frame(minHeight: 44)
            }
            .disabled(isExporting || savedLocations.isEmpty)

            // Import button
            Button {
                isImporting = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import Locations")

                    if isImporting {
                        Spacer()
                        ProgressView()
                            .tint(Theme.Colors.accent)
                    }
                }
                .frame(minHeight: 44)
            }
            .disabled(isImporting)

            // Delete button
            DeleteButton(isDeleting: isDeleting) {
                showDeleteConfirmation = true
            }
        } header: {
            Text("Data Management")
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .fileExporter(
            isPresented: $isExporting,
            document: LocationsCSV(locations: savedLocations),
            contentType: .commaSeparatedText,
            defaultFilename: "Locations-\(Date().formatted(.dateTime.year().month().day()))"
        ) { result in
            isExporting = false

            switch result {
            case .success(let url):
                feedbackMessage = "Locations exported successfully"
                isFeedbackError = false
                showFeedback = true
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
                feedbackMessage = "Failed to export locations"
                isFeedbackError = true
                showFeedback = true
            }

            // Hide feedback after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showFeedback = false
                }
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        .alert("Import Error", isPresented: $showImportError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(importError ?? "Unknown error occurred")
        })
    }

    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Dimensions.smallPadding) {
                HStack {
                    Text("Version")
                        .foregroundStyle(Theme.Colors.primaryText)
                    Spacer()
                    Text(Bundle.main.appVersion)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }

                HStack {
                    Text("Build")
                        .foregroundStyle(Theme.Colors.primaryText)
                    Spacer()
                    Text(Bundle.main.buildNumber)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            }
        } header: {
            Text("About")
                .foregroundStyle(Theme.Colors.secondaryText)
        }
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Theme.Colors.subtle)
                .imageScale(.large)
        }
    }

    private func setAppearance(_ isDark: Bool) {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        scene?.windows.first?.overrideUserInterfaceStyle = isDark ? .dark : .light
    }

    private func deleteAllLocations() async {
        await MainActor.run { isDeleting = true }

        do {
            try await Task.sleep(for: .seconds(0.5))

            let locationDescriptor = FetchDescriptor<SavedLocation>()
            let savedLocations = try modelContext.fetch(locationDescriptor)
            savedLocations.forEach { modelContext.delete($0) }

            let entryDescriptor = FetchDescriptor<LocationEntry>()
            let locationEntries = try modelContext.fetch(entryDescriptor)
            locationEntries.forEach { modelContext.delete($0) }

            try modelContext.save()

            await MainActor.run {
                isDeleting = false
                feedbackMessage = "All locations deleted successfully"
                isFeedbackError = false
                showFeedback = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showFeedback = false
                    }
                }
            }
        } catch {
            print("Failed to delete locations: \(error)")
            await MainActor.run {
                isDeleting = false
                feedbackMessage = "Failed to delete locations"
                isFeedbackError = true
                showFeedback = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showFeedback = false
                    }
                }
            }
        }
    }

    private func exportLocations() {
        isExporting = true
    }

    private var savedLocations: [SavedLocation] {
        let descriptor = FetchDescriptor<SavedLocation>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedFile = urls.first else { return }
            importLocations(from: selectedFile)
        case .failure(let error):
            importError = error.localizedDescription
            showImportError = true
        }
    }

    private func importLocations(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importError = "Cannot access the selected file"
            showImportError = true
            return
        }

        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try String(contentsOf: url)
            let rows = data.components(separatedBy: .newlines)

            // Skip header row
            guard rows.count > 1 else { throw ImportError.emptyFile }

            var importedCount = 0
            var duplicateCount = 0
            var errors: [String] = []

            // Process all rows first without saving
            for (index, row) in rows.dropFirst().enumerated() where !row.isEmpty {
                do {
                    let fields = parseCSVRow(row)


                    // Check for duplicates
                    if try isDuplicate(fields) {
                        duplicateCount += 1
                        continue
                    }

                    print(fields)
                    print("------")

                    try createLocation(from: fields)

                    importedCount += 1

                } catch ImportError.invalidData(let field) {
                    errors.append("Row \(index + 2): Invalid \(field)")
                } catch {
                    errors.append("Row \(index + 2): \(error.localizedDescription)")
                }
            }

            // Try to save context once at the end
            do {
                try modelContext.save()

                // Show appropriate feedback
                if !errors.isEmpty {
                    importError = "Imported \(importedCount) locations with \(errors.count) errors:\n" + errors.joined(separator: "\n")
                    showImportError = true
                } else if duplicateCount > 0 {
                    feedbackMessage = "\(importedCount) locations imported, \(duplicateCount) duplicates skipped"
                    isFeedbackError = false
                    showFeedback = true
                } else {
                    feedbackMessage = "\(importedCount) locations imported successfully"
                    isFeedbackError = false
                    showFeedback = true
                }
            } catch {
                throw ImportError.swiftDataError(error)
            }

        } catch {
            importError = error.localizedDescription
            showImportError = true
        }

        // Hide feedback after delay
        if showFeedback {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showFeedback = false
                }
            }
        }
    }

    private func isDuplicate(_ fields: [String]) throws -> Bool {
        do {
            guard fields.count >= 9 else { throw ImportError.invalidFormat }

            // Parse relevant fields for comparison
            let name = fields[0].replacingOccurrences(of: "\"", with: "")
            guard let latitude = Double(fields[4]),
                  let longitude = Double(fields[5]) else {
                throw ImportError.invalidData("coordinates")
            }

            // Create a simpler predicate that just checks the name first
            var nameDescriptor = FetchDescriptor<SavedLocation>()
            nameDescriptor.predicate = #Predicate<SavedLocation> { location in
                location.name == name
            }

            // Get potential matches by name
            let nameMatches = try modelContext.fetch(nameDescriptor)

            // Then manually check coordinates for those matches
            let isMatch = nameMatches.contains { location in
                guard let entry = location.locationEntry else { return false }

                let latDiff = abs(entry.latitude - latitude)
                let lonDiff = abs(entry.longitude - longitude)

                return latDiff <= 0.0001 && lonDiff <= 0.0001
            }

            return isMatch

        } catch let error as ImportError {
            throw error
        } catch {
            throw ImportError.swiftDataError(error)
        }
    }

    private func parseCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in row {
            switch char {
            case "\"":
                insideQuotes.toggle()
            case ",":
                if !insideQuotes {
                    fields.append(currentField)
                    currentField = ""
                } else {
                    currentField.append(char)
                }
            default:
                currentField.append(char)
            }
        }
        fields.append(currentField)

        return fields.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func createLocation(from fields: [String]) throws {
        guard fields.count >= 9 else { throw ImportError.invalidFormat }

        // Parse basic fields
        let name = fields[0].replacingOccurrences(of: "\"", with: "")
        let description = fields[1].replacingOccurrences(of: "\"", with: "")
        let street = fields[2].replacingOccurrences(of: "\"", with: "")
        let place = fields[3].replacingOccurrences(of: "\"", with: "")
        guard let latitude = Double(fields[4]) else { throw ImportError.invalidData("latitude") }
        guard let longitude = Double(fields[5]) else { throw ImportError.invalidData("longitude") }
        guard let isFavorite = Bool(fields[6]) else { throw ImportError.invalidData("favorite status") }

        // Create date formatter with the exact format from your CSV
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "dd/MM/yyyy, H:mm"

        // Parse created date
        let createdDateString = fields[7].replacingOccurrences(of: "\"", with: "")
        guard let createdDate = dateFormatter.date(from: createdDateString) else {
            print("Failed to parse date: \(createdDateString)")
            throw ImportError.invalidData("created date")
        }

        // Use the same date for timestamp if no separate timestamp provided
        let timestampString = fields[8].replacingOccurrences(of: "\"", with: "")
        let locationTimestamp = dateFormatter.date(from: timestampString) ?? createdDate

        // Create LocationEntry
        let entry = LocationEntry(
            latitude: latitude,
            longitude: longitude,
            timestamp: locationTimestamp,
            street: street.isEmpty ? nil : street,
            place: place.isEmpty ? nil : place
        )

        // Create SavedLocation
        let location = SavedLocation(
            name: name,
            locationDescription: description,
            locationEntry: entry,
            isFavorite: isFavorite
        )

        // Override the default creation date
        location.createdAt = createdDate

        // Insert both objects
        modelContext.insert(entry)
        modelContext.insert(location)
    }
}

struct ThemePreviewCircle: View {
    let theme: ThemeColor

    var body: some View {
        Circle()
            .fill(theme.accentColor)
            .frame(width: 24, height: 24)
    }
}

private struct ThemeSelectionRow: View {
    let theme: ThemeColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                ThemePreviewCircle(theme: theme)
                Text(theme.displayName)
                    .foregroundStyle(Theme.Colors.primaryText)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager.shared)
}

struct LocationsCSV: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    let locations: [SavedLocation]

    init(locations: [SavedLocation]) {
        self.locations = locations
    }

    init(configuration: ReadConfiguration) throws {
        locations = []
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Create header with all relevant fields
        var csvString = "Name,Description,Street,Place,Latitude,Longitude,Favorite,Created Date,Location Added Date\n"

        // Process each location
        for location in locations {
            let entry = location.locationEntry

            // Break down the array creation into multiple steps
            var rowData: [String] = []

            // Add location details
            rowData.append(location.name)
            rowData.append(location.locationDescription)

            // Add address components
            rowData.append(entry?.street ?? "")
            rowData.append(entry?.place ?? "")

            // Add coordinates
            rowData.append(String(entry?.latitude ?? 0))
            rowData.append(String(entry?.longitude ?? 0))

            // Add metadata
            rowData.append(String(location.isFavorite))
            rowData.append(location.createdAt.formatted(.dateTime))
            rowData.append(entry?.timestamp.formatted(.dateTime) ?? "")

            // Process fields
            let processedFields = rowData.map { field in
                let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escapedField)\""
            }

            // Join fields and add newline
            let row = processedFields.joined(separator: ",")
            csvString += row + "\n"
        }

        // Create and return file wrapper
        let csvData = Data(csvString.utf8)
        return FileWrapper(regularFileWithContents: csvData)
    }
}

enum ImportError: LocalizedError {
    case emptyFile
    case invalidFormat
    case swiftDataError(Error)
    case duplicateEntry
    case invalidData(String)

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The selected file is empty"
        case .invalidFormat:
            return "The file format is invalid"
        case .swiftDataError(let error):
            return "Database error: \(error.localizedDescription)"
        case .duplicateEntry:
            return "This location already exists"
        case .invalidData(let field):
            return "Invalid data for field: \(field)"
        }
    }
}

// Add this view component
private struct DeleteButton: View {
    let isDeleting: Bool
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            HStack {
                Image(systemName: "trash")
                Text("Delete All Locations")

                if isDeleting {
                    Spacer()
                    ProgressView()
                        .tint(.red)
                }
            }
            .frame(minHeight: 44) // Following Apple's minimum touch target size
        }
        .disabled(isDeleting)
    }
}
