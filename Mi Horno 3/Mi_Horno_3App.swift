// Mi_Horno_3App.swift
import SwiftUI
import Combine

@main
struct Mi_Horno_3App: App {
    @StateObject private var router = AppRouter()
    @StateObject private var lm     = LocalizationManager.shared
    @StateObject private var assistance = AssistanceOverlayModel()

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Bridge view — zero size, handles Apple Translation session
                TranslationBridgeView()
                    .environmentObject(lm)

                RootView()
                    .environmentObject(router)
                    .environmentObject(lm)

                AssistanceOverlayView()
                    .environmentObject(router)
                    .environmentObject(lm)
                    .environmentObject(assistance)

                // Overlay solo la primera vez en un idioma nuevo
                if lm.isTranslating {
                    TranslationLoadingOverlay()
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// Overlay de carga — primera vez por idioma
// ─────────────────────────────────────────────
struct TranslationLoadingOverlay: View {
    // Accede al singleton directamente — sin EnvironmentObject
    private let lm = LocalizationManager.shared
    @State private var dots = ""
    private let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                Image("horno3")
                    .resizable().scaledToFit()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    .shadow(color: Color.h3Orange.opacity(0.5), radius: 20)

                VStack(spacing: 10) {
                    ProgressView().tint(.white).scaleEffect(1.3)

                    Text("Preparando tu idioma\(dots)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text(lm.deviceLanguageName)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            .padding(36)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 20)
        }
        .onReceive(timer) { _ in
            dots = dots.count < 3 ? dots + "." : ""
        }
    }
}
