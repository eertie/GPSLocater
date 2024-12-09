import SwiftUI

struct ParticleEffect: View {
    let particleCount: Int
    @State private var particles: [(id: Int, x: Double, y: Double, scale: Double)] = []
    @State private var timer: Timer?

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.x * size.width,
                    y: particle.y * size.height,
                    width: 4,
                    height: 4
                )
                context.opacity = particle.scale
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(0.5))
                )
            }
        }
        .onAppear {
            particles = (0..<particleCount).map { id in
                (
                    id: id,
                    x: Double.random(in: 0...1),
                    y: Double.random(in: 0...1),
                    scale: Double.random(in: 0.2...0.7)
                )
            }

            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                withAnimation(.linear(duration: 0.05)) {
                    particles = particles.map { particle in
                        var newParticle = particle
                        newParticle.y -= 0.005
                        newParticle.x += Double.random(in: -0.002...0.002)
                        newParticle.scale += Double.random(in: -0.05...0.05)

                        if newParticle.y < 0 {
                            newParticle.y = 1
                            newParticle.x = Double.random(in: 0...1)
                        }
                        if newParticle.scale < 0.2 {
                            newParticle.scale = 0.2
                        } else if newParticle.scale > 0.7 {
                            newParticle.scale = 0.7
                        }
                        return newParticle
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var indicatorOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.Colors.accent.opacity(0.8),
                    Theme.Colors.accent
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Particle effect
//            ParticleEffect(particleCount: 50)
//                .opacity(isAnimating ? 1 : 0)
//
            VStack(spacing: 20) {
                // App logo with animations
                Image(systemName: "location.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: .white.opacity(0.5), radius: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            .scaleEffect(isAnimating ? 1.5 : 1)
                            .opacity(isAnimating ? 0 : 1)
                    )

                // App name
                Text("GPSLocater")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(textOpacity)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)

                // Loading indicator
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                    .opacity(indicatorOpacity)
            }
        }
        .onAppear {
            animateLaunchScreen()
        }
    }

    private func animateLaunchScreen() {
        withAnimation(.easeOut(duration: 0.5)) {
            isAnimating = true
        }

        // Logo animation
        withAnimation(.spring(duration: 0.7, bounce: 0.4)) {
            logoScale = 1.0
            logoOpacity = 1
        }

        // Text fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
            textOpacity = 1
        }

        // Loading indicator fade in
        withAnimation(.easeIn(duration: 0.3).delay(0.7)) {
            indicatorOpacity = 1
        }
    }
}

// Preview
#Preview {
    LaunchScreenView()
}
