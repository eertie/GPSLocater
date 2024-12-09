// MARK: - Components/WeatherSection.swift
import SwiftUI

struct WeatherSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let entry: LocationEntry
    @Binding var showWeather: Bool
    @Binding var currentWeather: WeatherData?
    @EnvironmentObject private var weatherManager: WeatherManager
    
    var body: some View {
        VStack(spacing: 12) {
            WeatherButton()
            
            if showWeather {
                WeatherView()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }//.padding(.horizontal, Theme.Dimensions.padding)
         //.padding(.vertical, Theme.Dimensions.smallPadding)
    }
    
    private func WeatherButton() -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showWeather.toggle()
                if showWeather && currentWeather == nil {
                    Task {
                        currentWeather = await WeatherManager.shared.fetchWeather(
                            latitude: entry.latitude,
                            longitude: entry.longitude
                        )
                    }
                }
            }
        }) {
            HStack {
                Label("Weather Information", systemImage: "cloud.sun.fill")
                Spacer()
                Image(systemName: showWeather ? "chevron.up.circle.fill" : "chevron.right.circle.fill")
            }
            .foregroundStyle(Theme.Colors.buttonText)
            .frame(height: Theme.Dimensions.buttonHeight)
            .padding(.horizontal, Theme.Dimensions.padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadius)
                    .fill(Theme.Colors.accent)
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
            )           
            .padding(.horizontal, Theme.Dimensions.padding) // Outer padding
            .padding(.vertical, Theme.Dimensions.smallPadding)
        }
    }
    
   
    private func WeatherView() -> some View {
        VStack(alignment: .leading) {
            if WeatherManager.shared.isLoading {
                WeatherLoadingView()
            } else if let error = WeatherManager.shared.error {
                WeatherErrorView(error: error)
            } else if let weather = currentWeather {
                WeatherContentView(weather: weather)
            } else {
                WeatherLoadingView()
                    .task {
                        currentWeather = await WeatherManager.shared.fetchWeather(
                            latitude: entry.latitude,
                            longitude: entry.longitude
                        )
                    }
            }
        }
        .padding(Theme.Dimensions.padding)
        .background(Theme.Colors.cardBackground)
        .padding(.horizontal, Theme.Dimensions.padding)
        .padding(.vertical, Theme.Dimensions.smallPadding)
       
    }
}

struct WeatherContentView: View {
    let weather: WeatherData
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: weather.condition.iconName)
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.Colors.warning)
                        
                        Text(String(format: "%.1f°", weather.temperature))
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(Theme.Colors.primaryText)
                    }
                    
                    Text(weather.condition.description)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    WeatherMetricView(
                        icon: "humidity.fill",
                        value: String(format: "%.0f%%", weather.humidity * 100),
                        label: "Humidity"
                    )
                    
                    WeatherMetricView(
                        icon: "wind",
                        value: String(format: "%.1f m/s", weather.windSpeed),
                        label: "Wind"
                    )
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Updated \(Date().formatted(.relative(presentation: .named)))")
                    .font(.caption2)
            }
            .foregroundStyle(Theme.Colors.secondaryText)
        }
    }
}

struct WeatherMetricView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Colors.primaryText)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
        }
    }
}

struct WeatherLoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .padding()
            Spacer()
        }
    }
}

struct WeatherErrorView: View {
    let error: WeatherError
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Colors.warning)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather Unavailable")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.primaryText)
                
                Text(error.localizedDescription)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.warning.opacity(0.1))
        )
    }
}
