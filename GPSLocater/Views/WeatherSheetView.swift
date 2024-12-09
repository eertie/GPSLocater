import SwiftUI


struct WeatherSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var weatherManager: WeatherManager
    let entry: LocationEntry
    @Binding var currentWeather: WeatherData?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if weatherManager.isLoading {
                        WeatherLoadingView()
                    } else if let error = weatherManager.error {
                        WeatherErrorView(error: error)
                    } else if let weather = currentWeather {
                        WeatherContentView(weather: weather)
                    } else {
                        WeatherLoadingView()
                            .task {
                                currentWeather = await weatherManager.fetchWeather(
                                    latitude: entry.latitude,
                                    longitude: entry.longitude
                                )
                            }
                    }
                }
                .padding()
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("Weather Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
    }
}


