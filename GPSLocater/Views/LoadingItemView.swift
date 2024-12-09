import SwiftUI

struct LoadingItemView: View {
    private let gradientColors: [Color] = [
        .gray.opacity(0.4),
        .gray.opacity(0.2),
        .gray.opacity(0.4)
    ]
    
    @State private var startPoint: UnitPoint = .init(x: -1, y: 0.5)
    @State private var endPoint: UnitPoint = .init(x: 0, y: 0.5)
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            .frame(height: 70)
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    startPoint = .init(x: 1, y: 0.5)
                    endPoint = .init(x: 2, y: 0.5)
                }
            }
    }
}
