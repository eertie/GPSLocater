
import SwiftUI

struct BackgroundGradientView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("TopColor"),
                Color("BottomColor")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct BackgroundGradientModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("TopColor"),
                        Color("BottomColor")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func withBackgroundGradient() -> some View {
        modifier(BackgroundGradientModifier())
    }
}

//
//// Usage in any view:
//struct SomeView: View {
//    var body: some View {
//        VStack {
//            // Your content
//        }
//        .withBackgroundGradient()
//    }
//}
