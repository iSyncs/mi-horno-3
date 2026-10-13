// RootView.swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            switch router.screen {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .login:
                LoginView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity))
            case .main:
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity))
            }
        }
        // Animación solo para transiciones de pantalla (splash→login→main)
        // NO para cambios de tab — eso lo maneja H3TabBar internamente
        .animation(.easeInOut(duration: 0.4), value: router.screen)
    }
}

#Preview {
    RootView()
        .environmentObject(AppRouter())
        .environmentObject(LocalizationManager.shared)
}
