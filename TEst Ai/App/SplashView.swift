import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool

    @State private var scale: CGFloat = 0.88
    // Логотип виден сразу, убираем стартовую прозрачность
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            // Градиентный фон, подобранный под картинку
            LinearGradient(
                colors: [
                    Color(red: 0.247, green: 0.639, blue: 1.000), // #3FA3FF (top)
                    Color(red: 0.173, green: 0.482, blue: 0.918)  // #2C7BEA (bottom)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Логотип
            Image("SplashImage")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .scaleEffect(scale)
                .opacity(opacity)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                .accessibilityLabel("Едем Вместе")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 2.35)) {
                    isFinished = true
                }
            }
        }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
