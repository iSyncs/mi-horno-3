import SwiftUI

struct BadgeUnlockOverlay: View {
    let badgeName: String
    let claimAction: () -> Void

    @State private var appearAnimation = false
    @State private var medalAnimation  = false
    @State private var glowPulse       = false
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            // Fondo oscuro
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            // Confeti del Wrapped (misma implementación)
            ConfettiLayer()

            // Tarjeta
            VStack(spacing: 0) {

                // ── Etiqueta superior ──────────────────────────────
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("INSIGNIA DESBLOQUEADA")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .kerning(1.2)
                }
                .foregroundColor(Color(hex: "#FFD60A"))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color(hex: "#FFD60A").opacity(0.15))
                .clipShape(Capsule())
                .padding(.bottom, 24)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : -12)

                // ── Título ─────────────────────────────────────────
                Text("¡Felicidades!")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 16)

                Text("Sigue por este camino")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.top, 6)
                    .padding(.bottom, 32)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 16)

                // ── Medalla ────────────────────────────────────────
                ZStack {
                    // Glow de fondo
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 200, height: 200)
                        .scaleEffect(glowPulse ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glowPulse)

                    Image(badgeName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .shadow(color: .white.opacity(0.18), radius: 24, y: 0)
                        .scaleEffect(medalAnimation ? 1.0 : 0.4)
                        .rotation3DEffect(
                            .degrees(medalAnimation ? 0 : 50),
                            axis: (x: 1.0, y: 0.5, z: 0.0)
                        )
                }
                .padding(.bottom, 36)

                // ── Botón ──────────────────────────────────────────
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    claimAction()
                }) {
                    Text("Reclamar insignia")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9F0A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "#FFD60A").opacity(0.35), radius: 14, y: 6)
                }
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 40)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(Color(hex: "#111111"))

                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.07), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 40, y: 20)
            .padding(.horizontal, 24)
            .scaleEffect(appearAnimation ? 1 : 0.88)
            .opacity(appearAnimation ? 1 : 0)
        }
        .onAppear {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                appearAnimation = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1)) {
                medalAnimation = true
            }
            withAnimation(.easeInOut(duration: 1.8).delay(0.4)) {
                glowPulse = true
            }
        }
    }
}
