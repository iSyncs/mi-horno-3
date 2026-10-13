// SplashView.swift
import SwiftUI

struct SplashView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme
    @State private var scale: CGFloat = 0.55
    @State private var opacity: Double = 0
    @State private var ring: CGFloat = 0

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.h3Black : Color.white).ignoresSafeArea()

            Circle()
                .stroke(Color.h3Orange.opacity(0.18), lineWidth: 1.5)
                .frame(width: 200 + ring * 160)
                .opacity(1 - ring)
                .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: ring)

            VStack(spacing: 20) {
                Image("horno3")
                    .resizable().scaledToFit()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .shadow(color: Color.h3Orange.opacity(0.45), radius: 28)

                VStack(spacing: 6) {
                    // Brand name never translates
                    Text("horno³")
                        .font(.system(size: 44, weight: .black))
                        .foregroundColor(scheme == .dark ? .h3TextOnDark : .h3TextOnLight)
                        .tracking(1.5)

                    // "MUSEO DEL ACERO" — same in all languages per museum branding
                    Text(L.appSubtitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.h3Orange)
                        .tracking(6)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.6)) {
                scale = 1.0; opacity = 1.0
            }
            ring = 0; withAnimation { ring = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                withAnimation(.easeInOut(duration: 0.45)) {
                    router.screen = .login
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AppRouter())
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
