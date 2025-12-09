import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool

    @State private var scale: CGFloat = 0.88
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                colors: [
                    Color(red: 0.29, green: 0.63, blue: 0.96), // #4AA1F5
                    Color(red: 0.23, green: 0.54, blue: 0.93)  // #3B8AD0
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Фото на весь экран (вписано, сохраняет пропорции)
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
                opacity = 1.0
                scale = 1.0
            }
            // Держим экран ~1.2 сек и завершаем
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    isFinished = true
                }
            }
        }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
