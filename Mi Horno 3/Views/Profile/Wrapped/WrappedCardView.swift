//
//  WrappedCardView.swift
//  Mi Horno 3
//

import SwiftUI
import UIKit

// ─────────────────────────────────────────────
// MARK: - Router principal
// Cada tipo de card tiene su propio layout y degradado único
// ─────────────────────────────────────────────

struct WrappedCardView: View {
    let card: WrappedCard
    var badges: [GamificationBadge] = []

    var body: some View {
        switch card.type {
        case .welcome:    WelcomeCard(card: card)
        case .challenges: ChallengesCard(card: card)
        case .accuracy:   AccuracyCard(card: card)
        case .medals:     MedalsCard(card: card, badges: badges)
        case .nickname:   NicknameCard(card: card)
        case .closing:    ClosingCard(card: card)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - 1. WELCOME  — centrado, grandioso
// Degradado: naranja fuego → magenta → dorado
// Ícono enorme, texto centrado, onda de pulso
// ─────────────────────────────────────────────

struct WelcomeCard: View {
    let card: WrappedCard
    @State private var appeared = false
    @State private var pulse    = false
    @State private var m        = false   // mesh toggle

    var body: some View {
        ZStack {
            // Mesh: naranja cálido + magenta + dorado
            MeshBG(animate: m, configs: [
                .init(color: Color(hex: "#FF6B35"), w: 1.2, h: 1.4, ox: m ?  0.10 : -0.15, oy: m ? -0.20 : -0.05, dur: 5.0, delay: 0.0),
                .init(color: Color(hex: "#FF2D78"), w: 0.90, h: 1.0, ox: m ? -0.10 :  0.15, oy: m ?  0.15 : -0.10, dur: 4.5, delay: 0.7),
                .init(color: Color(hex: "#FFD60A"), w: 0.70, h: 0.85, ox: m ?  0.20 : -0.05, oy: m ?  0.25 :  0.05, dur: 6.0, delay: 1.4),
                .init(color: Color(hex: "#FF9F0A"), w: 0.60, h: 0.70, ox: m ? -0.20 :  0.10, oy: m ? -0.30 :  0.10, dur: 4.8, delay: 2.0),
            ])

            Color.black.opacity(0.15)

            VStack(spacing: 0) {
                Spacer()

                // Ícono con aro de pulso
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(.white.opacity(pulse ? 0 : 0.25), lineWidth: 1.5)
                            .frame(width: CGFloat(90 + i * 34))
                            .scaleEffect(pulse ? 1.4 + CGFloat(i) * 0.2 : 1.0)
                            .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false).delay(Double(i) * 0.4), value: pulse)
                    }
                    Circle().fill(.white.opacity(0.22)).frame(width: 90)
                    Image(systemName: card.icon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.46).delay(0.1), value: appeared)
                }
                .padding(.bottom, 36)

                Text(card.title)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white.opacity(0.75))
                    .kerning(2.0)
                    .textCase(.uppercase)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: appeared)
                    .padding(.bottom, 14)

                Text(card.value)
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .animation(.spring(response: 0.55, dampingFraction: 0.55).delay(0.38), value: appeared)
                    .padding(.bottom, 24)

                Text(card.subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.80))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.50), value: appeared)
                    .padding(.horizontal, 32)

                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            appeared = true; m = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { pulse = true }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
        .onDisappear { appeared = false; pulse = false }
    }
}

// ─────────────────────────────────────────────
// MARK: - 2. CHALLENGES  — alineado abajo-izquierda, número gigante
// Degradado: naranja → amarillo → coral (blobs esquina superior-derecha)
// ─────────────────────────────────────────────

struct ChallengesCard: View {
    let card: WrappedCard
    @State private var appeared = false
    @State private var m        = false
    @State private var countedNum: Int = 0
    @State private var countTimer: Timer?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MeshBG(animate: m, configs: [
                .init(color: Color(hex: "#FF9F0A"), w: 1.3, h: 1.2, ox: m ?  0.30 :  0.10, oy: m ? -0.25 : -0.40, dur: 5.5, delay: 0.0),
                .init(color: Color(hex: "#FFD60A"), w: 0.80, h: 0.90, ox: m ?  0.10 : -0.15, oy: m ? -0.35 : -0.15, dur: 4.2, delay: 1.0),
                .init(color: Color(hex: "#FF6B35"), w: 0.65, h: 0.80, ox: m ? -0.10 :  0.20, oy: m ?  0.10 : -0.05, dur: 6.2, delay: 1.8),
                .init(color: Color(hex: "#FF453A"), w: 0.50, h: 0.60, ox: m ?  0.25 : -0.05, oy: m ?  0.30 :  0.10, dur: 4.8, delay: 2.5),
            ])
            Color.black.opacity(0.12)

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Número gigante con contador
                let parts = card.value.split(separator: "/")
                let denom = parts.count > 1 ? String(parts[1]) : ""
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("\(countedNum)")
                        .font(.system(size: 110, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText(countsDown: false))
                    Text("/\(denom)")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.50))
                        .padding(.bottom, 12)
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -60)
                .animation(.spring(response: 0.62, dampingFraction: 0.60).delay(0.30), value: appeared)

                // Título
                Text(card.title.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.18), value: appeared)
                    .padding(.bottom, 10)

                // Línea + subtítulo
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.55))
                        .frame(width: appeared ? 24 : 0, height: 2)
                        .animation(.spring(response: 0.4).delay(0.52), value: appeared)
                    Text(card.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.80))
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.56), value: appeared)
                }
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 36)
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            appeared = true; m = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { animateCount() }
        }
        .onDisappear { appeared = false; countedNum = 0; countTimer?.invalidate() }
    }

    private func animateCount() {
        let target = Int(card.value.split(separator: "/").first ?? "0") ?? 0
        countTo(target) { countedNum = $0 }
    }
    private func countTo(_ target: Int, assign: @escaping (Int) -> Void) {
        guard target > 0 else { assign(0); return }
        let steps = min(target, 50); let interval = 1.1 / Double(steps); var cur = 0
        countTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            cur += max(1, target / steps)
            if cur >= target { assign(target); t.invalidate() } else { assign(cur) }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - 3. ACCURACY  — centrado con arco de progreso
// Degradado: verde esmeralda → turquesa → azul (blobs dispersos)
// ─────────────────────────────────────────────

struct AccuracyCard: View {
    let card: WrappedCard
    @State private var appeared  = false
    @State private var m         = false
    @State private var arcTrim:  CGFloat = 0
    @State private var countedInt: Int   = 0
    @State private var countTimer: Timer?

    private var targetPct: Int { Int(card.value.replacingOccurrences(of: "%", with: "")) ?? 0 }

    var body: some View {
        ZStack {
            MeshBG(animate: m, configs: [
                .init(color: Color(hex: "#30D158"), w: 1.1, h: 1.3, ox: m ? -0.05 :  0.15, oy: m ? -0.20 :  0.05, dur: 6.0, delay: 0.0),
                .init(color: Color(hex: "#0A84FF"), w: 0.80, h: 0.95, ox: m ?  0.20 : -0.10, oy: m ?  0.25 : -0.10, dur: 5.0, delay: 0.9),
                .init(color: Color(hex: "#34C759"), w: 0.70, h: 0.80, ox: m ? -0.20 :  0.05, oy: m ? -0.10 :  0.20, dur: 4.5, delay: 1.6),
                .init(color: Color(hex: "#5AC8FA"), w: 0.55, h: 0.65, ox: m ?  0.10 : -0.20, oy: m ?  0.30 : -0.15, dur: 5.5, delay: 2.2),
            ])
            Color.black.opacity(0.18)

            VStack(spacing: 0) {
                // Arco de progreso arriba
                ZStack {
                    // Arco de fondo
                    Circle()
                        .trim(from: 0.12, to: 0.88)
                        .stroke(.white.opacity(0.18), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(90))
                        .frame(width: 160, height: 160)

                    // Arco de progreso
                    Circle()
                        .trim(from: 0.12, to: 0.12 + arcTrim * 0.76)
                        .stroke(.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(90))
                        .frame(width: 160, height: 160)
                        .animation(.spring(response: 1.2, dampingFraction: 0.75).delay(0.5), value: arcTrim)
                        .shadow(color: .white.opacity(0.6), radius: 6)

                    // Número centrado en el arco
                    VStack(spacing: 2) {
                        Text("\(countedInt)")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText(countsDown: false))
                        Text("%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.58).delay(0.1), value: appeared)
                .padding(.top, 52)
                .padding(.bottom, 36)

                // Ícono pequeño
                Image(systemName: card.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.70))
                    .padding(.bottom, 10)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut.delay(0.42), value: appeared)

                // Título
                Text(card.title.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.32), value: appeared)
                    .padding(.bottom, 16)

                // Subtítulo
                Text(card.subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.50), value: appeared)
                    .padding(.horizontal, 36)

                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            appeared = true; m = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                arcTrim = CGFloat(targetPct) / 100
                countTo(targetPct) { countedInt = $0 }
            }
        }
        .onDisappear { appeared = false; arcTrim = 0; countedInt = 0; countTimer?.invalidate() }
    }

    private func countTo(_ target: Int, assign: @escaping (Int) -> Void) {
        guard target > 0 else { assign(0); return }
        let steps = min(target, 50); let interval = 1.1 / Double(steps); var cur = 0
        countTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            cur += max(1, target / steps)
            if cur >= target { assign(target); t.invalidate() } else { assign(cur) }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - 4. MEDALS  — grid visual de medallas + número
// Degradado: púrpura → violeta → índigo (blobs a la derecha)
// ─────────────────────────────────────────────

struct MedalsCard: View {
    let card: WrappedCard
    let badges: [GamificationBadge]
    @State private var appeared   = false
    @State private var m          = false
    @State private var countedNum: Int = 0
    @State private var countTimer: Timer?

    private var unlocked: Int { Int(card.value.split(separator: "/").first ?? "0") ?? 0 }
    private var total:    Int { Int(card.value.split(separator: "/").last  ?? "6") ?? 6 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            MeshBG(animate: m, configs: [
                .init(color: Color(hex: "#BF5AF2"), w: 1.0, h: 1.3, ox: m ?  0.15 : -0.05, oy: m ? -0.15 : -0.30, dur: 5.2, delay: 0.0),
                .init(color: Color(hex: "#6E40C9"), w: 0.85, h: 1.0, ox: m ? -0.20 :  0.10, oy: m ?  0.20 : -0.05, dur: 4.8, delay: 1.0),
                .init(color: Color(hex: "#DA8FFF"), w: 0.70, h: 0.75, ox: m ?  0.25 : -0.10, oy: m ? -0.30 :  0.10, dur: 5.8, delay: 1.7),
                .init(color: Color(hex: "#0A84FF"), w: 0.55, h: 0.60, ox: m ? -0.05 :  0.20, oy: m ?  0.35 :  0.10, dur: 4.3, delay: 2.4),
            ])
            Color.black.opacity(0.16)

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: card.icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(.white.opacity(0.18))
                        .clipShape(Circle())
                        .scaleEffect(appeared ? 1 : 0)
                        .animation(.spring(response: 0.46, dampingFraction: 0.46).delay(0.08), value: appeared)

                    Text(card.title.replacingOccurrences(of: "\n", with: " "))
                        .font(.system(size: 19, weight: .black))
                        .foregroundColor(.white)
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : -20)
                        .animation(.spring(response: 0.48, dampingFraction: 0.7).delay(0.16), value: appeared)
                }
                .padding(.top, 48)
                .padding(.bottom, 32)

                // Insignias visuales — imagen real o candado
                let cols = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)
                LazyVGrid(columns: cols, spacing: 14) {
                    ForEach(Array(badges.enumerated()), id: \.offset) { i, badge in
                        ZStack {
                            Circle()
                                .fill(badge.unlocked ? Color.white.opacity(0.28) : Color.white.opacity(0.08))
                                .frame(width: 54, height: 54)
                            if badge.unlocked {
                                Image(badge.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                        }
                        .scaleEffect(appeared ? 1 : 0)
                        .animation(.spring(response: 0.44, dampingFraction: 0.52).delay(0.28 + Double(i) * 0.06), value: appeared)
                    }
                }
                .padding(.bottom, 28)

                // Número grande
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("\(countedNum)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText(countsDown: false))
                    Text("/\(total)")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.50))
                        .padding(.bottom, 8)
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -50)
                .animation(.spring(response: 0.60, dampingFraction: 0.62).delay(0.36), value: appeared)
                .padding(.bottom, 10)

                // Subtítulo
                Text(card.subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.78))
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.52), value: appeared)

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            appeared = true; m = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                countTo(unlocked) { countedNum = $0 }
            }
        }
        .onDisappear { appeared = false; countedNum = 0; countTimer?.invalidate() }
    }

    private func countTo(_ target: Int, assign: @escaping (Int) -> Void) {
        guard target > 0 else { assign(0); return }
        let steps = min(target, 30); let interval = 0.9 / Double(steps); var cur = 0
        countTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            cur += max(1, target / steps)
            if cur >= target { assign(target); t.invalidate() } else { assign(cur) }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - 5. NICKNAME  — apodo grande centrado, festivo
// Degradado: coral → naranja → rosa (blobs simétricos)
// ─────────────────────────────────────────────

struct NicknameCard: View {
    let card: WrappedCard
    @State private var appeared  = false
    @State private var m         = false
    @State private var iconSpin  = false

    var body: some View {
        ZStack {
            MeshBG(animate: m, configs: [
                .init(color: Color(hex: "#FF6B35"), w: 1.0, h: 1.2, ox: m ?  0.10 : -0.10, oy: m ? -0.20 : -0.05, dur: 5.0, delay: 0.0),
                .init(color: Color(hex: "#FF2D78"), w: 0.85, h: 0.95, ox: m ? -0.15 :  0.15, oy: m ?  0.15 : -0.15, dur: 4.6, delay: 0.8),
                .init(color: Color(hex: "#FF9F0A"), w: 0.70, h: 0.80, ox: m ?  0.20 : -0.05, oy: m ?  0.25 :  0.05, dur: 5.8, delay: 1.5),
                .init(color: Color(hex: "#BF5AF2"), w: 0.55, h: 0.65, ox: m ? -0.10 :  0.15, oy: m ? -0.25 :  0.10, dur: 4.4, delay: 2.2),
            ])
            Color.black.opacity(0.14)

            VStack(spacing: 0) {
                Spacer()

                // Ícono con rotación completa al aparecer
                Image(systemName: card.icon)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(iconSpin ? 360 : 0))
                    .scaleEffect(appeared ? 1.0 : 0.2)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.52, dampingFraction: 0.46).delay(0.1), value: appeared)
                    .padding(.bottom, 28)

                // Etiqueta "Tu apodo"
                Text(card.title.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white.opacity(0.68))
                    .kerning(2.5)
                    .textCase(.uppercase)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut.delay(0.26), value: appeared)
                    .padding(.bottom, 16)

                // Nombre grande — cada palabra en su línea, entra desde abajo
                let words = card.value.split(separator: " ").map(String.init)
                VStack(spacing: 2) {
                    ForEach(Array(words.enumerated()), id: \.offset) { i, word in
                        Text(word)
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .offset(y: appeared ? 0 : 50)
                            .opacity(appeared ? 1 : 0)
                            .blur(radius: appeared ? 0 : 8)
                            .animation(.spring(response: 0.55, dampingFraction: 0.60).delay(0.38 + Double(i) * 0.14), value: appeared)
                    }
                }
                .padding(.bottom, 28)

                // Descripción del apodo en pill
                Text(card.subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .animation(.spring(response: 0.50, dampingFraction: 0.68).delay(0.60), value: appeared)
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            appeared = true; m = true
            // Haptic festivo: double tap
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.5)) { iconSpin = true }
            }
        }
        .onDisappear { appeared = false; iconSpin = false }
    }
}

// ─────────────────────────────────────────────
// MARK: - 6. CLOSING  — emocional, líneas de corazón
// Degradado: rojo → coral → rosa (partículas de corazón)
// ─────────────────────────────────────────────

struct ClosingCard: View {
    let card: WrappedCard
    @State private var appeared = false
    @State private var m        = false
    @State private var hearts:  [HeartParticle] = []
    @State private var heartsTick = false

    var body: some View {
        ZStack {
            MeshBG(animate: m, configs: [
                .init(color: Color(hex: "#FF453A"), w: 1.1, h: 1.3, ox: m ?  0.05 : -0.10, oy: m ? -0.20 : -0.05, dur: 5.5, delay: 0.0),
                .init(color: Color(hex: "#FF6B35"), w: 0.85, h: 1.0, ox: m ? -0.15 :  0.15, oy: m ?  0.20 : -0.10, dur: 4.8, delay: 0.9),
                .init(color: Color(hex: "#FF6B9D"), w: 0.70, h: 0.80, ox: m ?  0.20 : -0.05, oy: m ? -0.15 :  0.20, dur: 6.0, delay: 1.6),
                .init(color: Color(hex: "#BF5AF2"), w: 0.50, h: 0.60, ox: m ? -0.10 :  0.18, oy: m ?  0.28 : -0.08, dur: 4.5, delay: 2.3),
            ])
            Color.black.opacity(0.16)

            // Corazones flotantes
            GeometryReader { geo in
                ForEach(hearts) { h in
                    Text("♥")
                        .font(.system(size: h.size))
                        .foregroundColor(.white.opacity(heartsTick ? h.opacity : h.opacity * 0.2))
                        .position(
                            x: geo.size.width  * h.x + (heartsTick ? h.dx : 0),
                            y: geo.size.height * h.y + (heartsTick ? h.dy : 0)
                        )
                        .animation(.easeInOut(duration: h.dur).repeatForever(autoreverses: true).delay(h.delay), value: heartsTick)
                }
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()
                Spacer()

                // Ícono grande
                Image(systemName: card.icon)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(appeared ? 1.0 : 0.1)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.52, dampingFraction: 0.44).delay(0.1), value: appeared)
                    .shadow(color: .white.opacity(0.5), radius: 20)
                    .padding(.bottom, 32)

                // Valor grande
                Text(card.value)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .animation(.spring(response: 0.55, dampingFraction: 0.55).delay(0.28), value: appeared)
                    .padding(.bottom, 10)

                // Título
                Text(card.title.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white.opacity(0.80))
                    .kerning(0.5)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.40), value: appeared)
                    .padding(.bottom, 28)
                    .padding(.horizontal, 32)

                // Subtítulo
                Text(card.subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.54), value: appeared)
                    .padding(.horizontal, 36)

                Spacer()
                Spacer()
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            appeared = true; m = true
            hearts = HeartParticle.generate(count: 14)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { heartsTick = true }
            // Haptic especial de cierre
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
        .onDisappear { appeared = false; heartsTick = false }
    }
}

struct HeartParticle: Identifiable {
    let id = UUID()
    let x: CGFloat; let y: CGFloat
    let dx: CGFloat; let dy: CGFloat
    let size: CGFloat; let opacity: Double
    let dur: Double; let delay: Double

    static func generate(count: Int) -> [HeartParticle] {
        (0..<count).map { _ in
            HeartParticle(
                x: CGFloat.random(in: 0.05...0.95),
                y: CGFloat.random(in: 0.05...0.95),
                dx: CGFloat.random(in: -18...18),
                dy: CGFloat.random(in: -22...22),
                size: CGFloat.random(in: 10...26),
                opacity: Double.random(in: 0.08...0.30),
                dur: Double.random(in: 1.8...4.0),
                delay: Double.random(in: 0...2.5)
            )
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - MeshBG  — sistema de blobs reutilizable
// Cada card pasa sus propias configs de color y posición
// ─────────────────────────────────────────────

struct BlobConfig {
    let color:  Color
    let w:      CGFloat   // ancho relativo al contenedor
    let h:      CGFloat   // alto relativo al contenedor
    let ox:     CGFloat   // offset X relativo (posición cuando animate==true)
    let oy:     CGFloat   // offset Y relativo
    let dur:    Double
    let delay:  Double
}

struct MeshBG: View {
    let animate: Bool
    let configs: [BlobConfig]

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            ZStack {
                // Fondo negro como base, los blobs colorean encima
                Color.black

                ForEach(Array(configs.enumerated()), id: \.offset) { i, cfg in
                    Ellipse()
                        .fill(cfg.color)
                        .frame(width: W * cfg.w, height: H * cfg.h)
                        .offset(x: animate ? cfg.ox * W : -cfg.ox * W * 0.5,
                                y: animate ? cfg.oy * H : -cfg.oy * H * 0.5)
                        .animation(
                            .easeInOut(duration: cfg.dur)
                            .repeatForever(autoreverses: true)
                            .delay(cfg.delay),
                            value: animate
                        )
                        .blur(radius: 28 + CGFloat(i) * 4)
                        .opacity(0.82 - Double(i) * 0.06)
                }
            }
            .drawingGroup()
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Partícula (para WrappedView si se necesita)
// ─────────────────────────────────────────────

struct Particle: Identifiable {
    let id = UUID()
    let x: CGFloat; let y: CGFloat
    let driftX: CGFloat; let driftY: CGFloat
    let size: CGFloat; let opacity: Double
    let duration: Double; let delay: Double

    static func generate(count: Int, in rect: CGRect) -> [Particle] {
        (0..<count).map { _ in
            Particle(
                x: CGFloat.random(in: rect.minX...rect.maxX),
                y: CGFloat.random(in: rect.minY...rect.maxY),
                driftX: CGFloat.random(in: -14...14), driftY: CGFloat.random(in: -20...20),
                size: CGFloat.random(in: 2.5...7),
                opacity: Double.random(in: 0.08...0.28),
                duration: Double.random(in: 1.8...4.2),
                delay: Double.random(in: 0...2.4)
            )
        }
    }
}

#Preview {
    ZStack {
        Color.h3Black.ignoresSafeArea()
        WrappedCardView(card: WrappedCard(
            type: .accuracy, title: "Tu precisión", value: "87%",
            subtitle: "Casi perfecto. ¡Gran ojo!", icon: "checkmark.seal.fill",
            color: Color(hex: "#30D158"), accentColor: Color(hex: "#34C759")
        )).padding(16)
    }
}
