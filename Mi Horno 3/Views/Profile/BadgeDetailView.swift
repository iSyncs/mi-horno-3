// BadgeDetailView.swift
// Vista de detalle de medalla — efecto 3D con giroscopio
// Textos sin gradiente, adaptativos dark/light, 100% localizados

import SwiftUI
import CoreMotion
import Combine

// ─────────────────────────────────────────────
// MARK: - Motion Manager
// ─────────────────────────────────────────────

final class MotionManager: ObservableObject {
    @Published var tiltX: Double = 0
    @Published var tiltY: Double = 0

    private let manager = CMMotionManager()
    private let maxTilt = 20.0

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let maxRad = self.maxTilt * .pi / 180.0
            DispatchQueue.main.async {
                self.tiltX = max(-1, min(1,  motion.attitude.roll  / maxRad))
                self.tiltY = max(-1, min(1,  motion.attitude.pitch / maxRad))
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        DispatchQueue.main.async { self.tiltX = 0; self.tiltY = 0 }
    }
}

// ─────────────────────────────────────────────
// MARK: - BadgeDetailView
// ─────────────────────────────────────────────

struct BadgeDetailView: View {
    let badge: GamificationBadge
    var onDismiss: () -> Void = {}

    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme
    @StateObject private var motion = MotionManager()

    // Tilt suavizado
    @State private var smoothX: Double = 0
    @State private var smoothY: Double = 0

    // Fondo
    @State private var bgOpacity: Double = 0

    // Medalla
    @State private var medalScale:   CGFloat = 0.25
    @State private var medalOpacity: Double  = 0

    // Textos — cada uno animado por separado
    @State private var nameOffset:  CGFloat = 28
    @State private var nameOpacity: Double  = 0
    @State private var pillOffset:  CGFloat = 22
    @State private var pillOpacity: Double  = 0
    @State private var hintOpacity: Double  = 0

    // Botón cerrar
    @State private var closeOpacity: Double = 0

    // Celebración (solo desbloqueadas)
    @State private var burstScale:   CGFloat = 0.1
    @State private var burstOpacity: Double  = 0
    @State private var ringScale:    CGFloat = 0.6
    @State private var ringOpacity:  Double  = 0

    // Partículas
    @State private var particlePhase: Double = 0

    // ── Colores adaptativos ────────────────────────────────────────────
    // El fondo de la view siempre es oscuro (gradiente de colores de medalla)
    // pero los textos se ajustan para máxima legibilidad sobre ese fondo.
    // En este caso el fondo siempre es oscuro, así que el texto es siempre blanco.
    // La pill de nivel usa el color de acento con opacidad para que funcione en ambos modos.

    var body: some View {
        ZStack {
            backdrop.ignoresSafeArea()
            particleField.opacity(bgOpacity * 0.45)

            VStack(spacing: 0) {

                // ── Botón cerrar ──────────────────────────────────────────
                HStack {
                    Spacer()
                    Button(action: dismissWithAnimation) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 38, height: 38)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .opacity(closeOpacity)

                Spacer()

                // ── Medalla ───────────────────────────────────────────────
                medalView
                    .scaleEffect(medalScale)
                    .opacity(medalOpacity)
                    .frame(width: 340, height: 340)

                Spacer()

                // ── Textos ─────────────────────────────────────────────────
                VStack(spacing: 16) {

                    // Nombre — blanco puro, grande, sin gradiente
                    // El fondo oscuro garantiza contraste siempre
                    Text(badge.displayName.uppercased())
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .offset(y: nameOffset)
                        .opacity(nameOpacity)

                    // Pill de nivel — texto blanco, fondo con color de acento
                    levelPill
                        .offset(y: pillOffset)
                        .opacity(pillOpacity)

                    // Hint si está bloqueada
                    if !badge.unlocked {
                        Text(lm.s(L.badgeLockedHint))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .opacity(hintOpacity)
                    }
                }
                .padding(.bottom, 64)
            }
        }
        .onAppear {
            motion.start()
            runEntrySequence()
            startParticleAnimation()
        }
        .onDisappear { motion.stop() }
        .onChange(of: motion.tiltX) { _, val in
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) { smoothX = val }
        }
        .onChange(of: motion.tiltY) { _, val in
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) { smoothY = val }
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Fondo
    // ─────────────────────────────────────────────

    private var backdrop: some View {
        ZStack {
            // Gradiente radial principal — siempre oscuro
            RadialGradient(
                colors: badge.backdropColors + [.black],
                center: .init(x: 0.5 + smoothX * 0.18, y: 0.42 + smoothY * 0.12),
                startRadius: 0,
                endRadius: 640
            )
            .animation(.interactiveSpring(response: 0.55), value: smoothX)
            .animation(.interactiveSpring(response: 0.55), value: smoothY)

            // Viñeta
            RadialGradient(
                colors: [.clear, .black.opacity(0.6)],
                center: .center,
                startRadius: 160,
                endRadius: 520
            )

            // Orbe de luz que sigue el tilt
            badge.accentColor
                .opacity(0.2)
                .frame(width: 360, height: 360)
                .blur(radius: 95)
                .offset(x: smoothX * 70, y: smoothY * 50)
                .animation(.interactiveSpring(response: 0.65), value: smoothX)
                .animation(.interactiveSpring(response: 0.65), value: smoothY)
        }
        .opacity(bgOpacity)
    }

    // ─────────────────────────────────────────────
    // MARK: Partículas
    // ─────────────────────────────────────────────

    private var particleField: some View {
        GeometryReader { geo in
            ForEach(0..<14, id: \.self) { i in
                let seed  = Double(i) * 1.618
                let px    = geo.size.width  * (seed.truncatingRemainder(dividingBy: 7) / 7)
                let py    = geo.size.height * (seed.truncatingRemainder(dividingBy: 5) / 5)
                let size  = CGFloat(3 + (i % 4) * 3)
                let speed = 0.5 + Double(i % 3) * 0.35
                Circle()
                    .fill(badge.accentColor.opacity(0.22 + Double(i % 3) * 0.12))
                    .frame(width: size, height: size)
                    .blur(radius: size * 0.4)
                    .position(
                        x: px + sin(particlePhase * speed + seed) * 20,
                        y: py + cos(particlePhase * speed * 0.8 + seed) * 24
                    )
            }
        }
        .ignoresSafeArea()
    }

    // ─────────────────────────────────────────────
    // MARK: Medalla
    // ─────────────────────────────────────────────

    private var medalView: some View {
        ZStack {
            // Anillo de celebración (solo desbloqueadas)
            if badge.unlocked {
                Circle()
                    .stroke(badge.accentColor.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 320, height: 320)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
            }

            // Resplandor difuso detrás — no tiene forma visible
            badge.accentColor
                .opacity(0.38)
                .frame(width: 290, height: 290)
                .blur(radius: 62)
                .offset(x: smoothX * 14, y: smoothY * 10)
                .animation(.interactiveSpring(response: 0.45), value: smoothX)
                .animation(.interactiveSpring(response: 0.45), value: smoothY)

            // Sombra al suelo
            Ellipse()
                .fill(.black.opacity(0.38))
                .frame(width: 200, height: 22)
                .blur(radius: 20)
                .offset(x: smoothX * 18, y: 168 + smoothY * 10)
                .animation(.interactiveSpring(response: 0.45), value: smoothX)
                .animation(.interactiveSpring(response: 0.45), value: smoothY)

            // Ráfaga de celebración
            if badge.unlocked {
                BurstShape()
                    .fill(badge.accentColor.opacity(0.45))
                    .frame(width: 360, height: 360)
                    .scaleEffect(burstScale)
                    .opacity(burstOpacity)
                    .allowsHitTesting(false)
            }

            // La imagen de la medalla
            Group {
                if badge.unlocked {
                    Image(badge.imageName)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(badge.imageName)
                        .resizable()
                        .scaledToFit()
                        .grayscale(1.0)
                        .opacity(0.3)
                }
            }
            .frame(width: 310, height: 310)
            .shadow(color: badge.accentColor.opacity(badge.unlocked ? 0.75 : 0.15), radius: 44, y: 14)
            .shadow(color: .black.opacity(0.5), radius: 22, y: 8)
            .rotation3DEffect(.degrees(smoothX * 22), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .rotation3DEffect(.degrees(-smoothY * 16), axis: (x: 1, y: 0, z: 0), perspective: 0.4)
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Pill de nivel — texto siempre blanco
    // ─────────────────────────────────────────────

    private var levelPill: some View {
        let name = badge.imageName.lowercased()
        let (label, icon): (String, String) = {
            if name.contains("oro")       { return (lm.s(L.badgeLevelGold),    "crown.fill") }
            if name.contains("plata")     { return (lm.s(L.badgeLevelSilver),  "star.fill") }
            if name.contains("bronce")    { return (lm.s(L.badgeLevelBronze),  "seal.fill") }
            if name.contains("master")    { return (lm.s(L.badgeLabelMaster),  "bolt.fill") }
            if name.contains("descargar") { return (lm.s(L.badgeLabelPioneer), "arrow.down.app.fill") }
            if name.contains("encuesta")  { return (lm.s(L.badgeLabelVoice),   "bubble.left.fill") }
            return (lm.s(L.badgeLabelSpecial), "sparkles")
        }()

        return HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
            Text(badge.unlocked ? label : lm.s(L.badgeLocked))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .kerning(0.3)
        }
        // Siempre blanco — el fondo oscuro garantiza legibilidad
        .foregroundColor(.white)
        .padding(.horizontal, 22)
        .padding(.vertical, 11)
        .background(
            Capsule()
                // Fondo con color de acento semitransparente — funciona en dark y light
                .fill(badge.unlocked ? badge.accentColor.opacity(0.35) : .white.opacity(0.12))
                .overlay(
                    Capsule().stroke(
                        badge.unlocked ? badge.accentColor.opacity(0.7) : .white.opacity(0.2),
                        lineWidth: 1.5
                    )
                )
        )
        .shadow(color: badge.unlocked ? badge.accentColor.opacity(0.4) : .clear, radius: 12)
    }

    // ─────────────────────────────────────────────
    // MARK: Secuencia de entrada animada
    // ─────────────────────────────────────────────

    private func runEntrySequence() {
        // 1. Fondo aparece
        withAnimation(.easeOut(duration: 0.38)) { bgOpacity = 1 }

        // 2. Botón cerrar
        withAnimation(.easeOut(duration: 0.3).delay(0.15)) { closeOpacity = 1 }

        // 3. Medalla entra con rebote
        withAnimation(.spring(response: 0.62, dampingFraction: 0.56).delay(0.08)) {
            medalScale   = 1.0
            medalOpacity = 1
        }

        // 4. Si está desbloqueada → ráfaga + anillo + haptic
        if badge.unlocked {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                withAnimation(.easeOut(duration: 0.5))  { burstScale = 1.0; burstOpacity = 1.0 }
                withAnimation(.easeIn(duration: 0.32).delay(0.32)) { burstOpacity = 0 }
                withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                    ringScale = 1.0; ringOpacity = 0.85
                }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }

        // 5. Nombre sube desde abajo con fade
        withAnimation(.spring(response: 0.48, dampingFraction: 0.7).delay(0.28)) {
            nameOffset = 0; nameOpacity = 1
        }

        // 6. Pill sube un poco después
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72).delay(0.40)) {
            pillOffset = 0; pillOpacity = 1
        }

        // 7. Hint (bloqueada) aparece al final
        withAnimation(.easeOut(duration: 0.3).delay(0.52)) { hintOpacity = 1 }
    }

    // ─────────────────────────────────────────────
    // MARK: Salida
    // ─────────────────────────────────────────────

    private func dismissWithAnimation() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            medalScale   = 0.25
            medalOpacity = 0
            bgOpacity    = 0
            nameOpacity  = 0
            pillOpacity  = 0
            closeOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { onDismiss() }
    }

    private func startParticleAnimation() {
        withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
            particlePhase = .pi * 2
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Burst shape (rayos de celebración)
// ─────────────────────────────────────────────

struct BurstShape: Shape {
    var rays: Int = 12
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center  = CGPoint(x: rect.midX, y: rect.midY)
        let outerR  = min(rect.width, rect.height) / 2
        let innerR  = outerR * 0.42
        let step    = Double.pi * 2 / Double(rays)
        for i in 0..<rays {
            let outer = Double(i) * step - .pi / 2
            let inner = outer + step / 2
            let op = CGPoint(x: center.x + CGFloat(cos(outer)) * outerR, y: center.y + CGFloat(sin(outer)) * outerR)
            let ip = CGPoint(x: center.x + CGFloat(cos(inner)) * innerR, y: center.y + CGFloat(sin(inner)) * innerR)
            if i == 0 { path.move(to: op) } else { path.addLine(to: op) }
            path.addLine(to: ip)
        }
        path.closeSubpath()
        return path
    }
}

// ─────────────────────────────────────────────
// MARK: - Previews
// ─────────────────────────────────────────────

#Preview("Oro — desbloqueada") {
    BadgeDetailView(
        badge: GamificationBadge(
            imageName: "historia_oro", displayName: "Historia",
            unlocked: true, isNewlyClaimed: false
        )
    )
    .environmentObject(LocalizationManager.shared)
}

#Preview("Plata — desbloqueada") {
    BadgeDetailView(
        badge: GamificationBadge(
            imageName: "general_plata", displayName: "General",
            unlocked: true, isNewlyClaimed: false
        )
    )
    .environmentObject(LocalizationManager.shared)
}

#Preview("Bronce — bloqueada") {
    BadgeDetailView(
        badge: GamificationBadge(
            imageName: "acero_bronce", displayName: "Acero",
            unlocked: false, isNewlyClaimed: false
        )
    )
    .environmentObject(LocalizationManager.shared)
}

#Preview("Máster Desafíos") {
    BadgeDetailView(
        badge: GamificationBadge(
            imageName: "masterdesafios", displayName: "Máster",
            unlocked: true, isNewlyClaimed: true
        )
    )
    .environmentObject(LocalizationManager.shared)
}
