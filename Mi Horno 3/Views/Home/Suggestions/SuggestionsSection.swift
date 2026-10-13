// SuggestionsSection.swift
// Galería horizontal con scrollTransition + flip 3D por categoría
// Cara trasera se adapta a # de atracciones. Detalle full-card llamativo.

import SwiftUI

// MARK: - Constantes de tamaño
private let kCardWidth:     CGFloat = 300
private let kRowHeight:     CGFloat = 66
private let kBackTopBar:    CGFloat = 68
private let kBackBottomPad: CGFloat = 12

// Altura fija para TODOS — igual a Shows (3 atracciones) = 278
private let kCardHeight: CGFloat = 68 + 3 * 66 + 12  // 278

private func backHeight(for count: Int) -> CGFloat { kCardHeight }
private func cardHeight(for count: Int) -> CGFloat { kCardHeight }

struct SuggestionsSection: View {
    @EnvironmentObject var lm: LocalizationManager
    @ObservedObject var vm: HomeViewModel
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header ────────────────────────────────────────────
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lm.s(L.homeSuggestionsTitle))
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(Color.h3Text(scheme))
                    HStack(spacing: 5) {
                        Circle()
                            .fill(vm.isMuseumOpen ? Color.green : Color.red)
                            .frame(width: 7, height: 7)
                        Text(vm.isMuseumOpen ? lm.s(L.museumOpen) : lm.s(L.museumClosed))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(vm.isMuseumOpen ? .green : .red)
                    }
                }
                Spacer()
                Text(vm.currentTime, style: .time)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.h3Sub(scheme))
            }
            .padding(.horizontal, 24)

            if vm.isMuseumOpen {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(MuseumCatalog.groups) { group in
                            FlipGroupCard(group: group, vm: vm)
                                .scrollTransition(axis: .horizontal) { content, phase in
                                    content
                                        .rotationEffect(.degrees(phase.value * 3.5))
                                        .offset(y: phase.isIdentity ? 0 : 10)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.94)
                                }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
            } else {
                MuseumClosedBanner()
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Flip Group Card
struct FlipGroupCard: View {
    @EnvironmentObject var lm: LocalizationManager
    let group: AttractionGroup
    @ObservedObject var vm: HomeViewModel

    @State private var isFlipped:        Bool       = false
    @State private var rotation:         Double     = 0
    @State private var pulse:            Bool       = false
    @State private var detailAttraction: Attraction? = nil
    @State private var showDetail:       Bool       = false

    // Altura total: la mayor entre frente y trasera
    private var totalHeight: CGFloat { cardHeight(for: group.attractions.count) }

    var body: some View {
        ZStack {
            // ── CARA FRONTAL ──────────────────────────────────────
            FrontFace(group: group, lm: lm, pulse: pulse, totalHeight: totalHeight)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.4)

            // ── CARA TRASERA ──────────────────────────────────────
            BackFace(
                group: group,
                lm: lm,
                totalHeight: totalHeight,
                onFlipBack: flipToFront,
                onSelectAttraction: { attraction in
                    detailAttraction = attraction
                    withAnimation(.spring(response: 0.48, dampingFraction: 0.8)) {
                        showDetail = true
                    }
                }
            )
            .opacity(isFlipped && !showDetail ? 1 : 0)
            .rotation3DEffect(.degrees(rotation - 180), axis: (x: 0, y: 1, z: 0), perspective: 0.4)

            // ── DETALLE FULL-CARD ─────────────────────────────────
            if let attraction = detailAttraction {
                AttractionDetailCard(
                    attraction: attraction,
                    lm: lm,
                    totalHeight: totalHeight,
                    onBack: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            showDetail = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            detailAttraction = nil
                        }
                    }
                )
                .opacity(showDetail ? 1 : 0)
                .scaleEffect(showDetail ? 1.0 : 0.86)
                .rotation3DEffect(
                    .degrees(showDetail ? 0 : -18),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
            }
        }
        .frame(width: kCardWidth, height: totalHeight)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(
            color: isFlipped
                ? group.accentColor.opacity(0.22)
                : Color.black.opacity(0.28),
            radius: 18, x: 0, y: 8
        )
        .onTapGesture { if !isFlipped { flipToBack() } }
        .onAppear { pulse = true }
        .animation(.spring(response: 0.35), value: showDetail)
    }

    private func flipToBack() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            rotation += 180; isFlipped = true
        }
    }

    private func flipToFront() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            rotation += 180; isFlipped = false
            showDetail = false; detailAttraction = nil
        }
    }
}

// MARK: - Cara Frontal
private struct FrontFace: View {
    let group: AttractionGroup
    let lm: LocalizationManager
    let pulse: Bool
    let totalHeight: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: group.gradientColors,
                                     startPoint: .topLeading, endPoint: .bottomTrailing))

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: pulse ? 170 : 148)
                .offset(x: kCardWidth - 80, y: -totalHeight * 0.32)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulse)

            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: pulse ? 100 : 82)
                .offset(x: kCardWidth - 50, y: -totalHeight * 0.12)
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(0.7), value: pulse)

            Image(systemName: group.icon)
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.17))
                .offset(x: kCardWidth - 120, y: -totalHeight * 0.28)
                .scaleEffect(pulse ? 1.05 : 0.96)
                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: pulse)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 5) {
                    scheduleIcon(for: group.subtitleKey).font(.system(size: 10))
                    Text(lm.s(group.subtitleKey)).font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.88))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.white.opacity(0.18)).cornerRadius(20)

                Text(lm.s(group.titleKey))
                    .font(.system(size: 26, weight: .black)).foregroundColor(.white)

                HStack(spacing: 5) {
                    Image(systemName: "hand.tap.fill").font(.system(size: 11))
                    Text(String(format: lm.s(L.attractionsCount), group.attractions.count)).font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
        }
        .frame(width: kCardWidth, height: totalHeight)
    }

    @ViewBuilder
    private func scheduleIcon(for key: String) -> some View {
        switch key {
        case L.scheduleClimate:      Image(systemName: "cloud.sun.fill")
        case L.scheduleAvailability: Image(systemName: "ticket.fill")
        default:                     Image(systemName: "clock.fill")
        }
    }
}

// MARK: - Cara Trasera
private struct BackFace: View {
    let group: AttractionGroup
    let lm: LocalizationManager
    let totalHeight: CGFloat
    let onFlipBack: () -> Void
    let onSelectAttraction: (Attraction) -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 0) {
            // Barra superior con gradiente sutil
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: group.gradientColors,
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 34, height: 34)
                    Image(systemName: group.icon)
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                }
                Text(lm.s(group.titleKey))
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(Color.h3Text(scheme))
                Spacer()
                Button(action: onFlipBack) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 26)).foregroundStyle(group.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().background(group.accentColor.opacity(0.2)).padding(.horizontal, 16)

            // Filas de atracciones — altura fija por fila
            VStack(spacing: 0) {
                ForEach(Array(group.attractions.enumerated()), id: \.element.id) { idx, attraction in
                    Button { onSelectAttraction(attraction) } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(attraction.accentColor.opacity(0.15))
                                    .frame(width: 38, height: 38)
                                Image(systemName: attraction.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(attraction.accentColor)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lm.s(attraction.nameKey))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.h3Text(scheme))
                                    .lineLimit(1)
                                Text(lm.s(attraction.scheduleKey))
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.h3Sub(scheme))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(group.accentColor.opacity(0.6))
                        }
                        .frame(height: kRowHeight)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if idx < group.attractions.count - 1 {
                        Divider().background(Color.h3Separator(scheme)).padding(.leading, 66)
                    }
                }
            }

            Spacer(minLength: kBackBottomPad)
        }
        .frame(width: kCardWidth, height: totalHeight)
        .background(Color.h3Card(scheme))
    }
}

// MARK: - Detalle full-card de atracción
private struct AttractionDetailCard: View {
    let attraction: Attraction
    let lm: LocalizationManager
    let totalHeight: CGFloat
    let onBack: () -> Void

    @State private var pulse      = false
    @State private var shimmer    = false
    @State private var sparkles: [SparkleParticle] = SparkleParticle.random(count: 6)

    var body: some View {
        ZStack(alignment: .topLeading) {

            // ── Fondo ─────────────────────────────────────────────
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            attraction.accentColor,
                            attraction.accentColor.opacity(0.55),
                            attraction.accentColor.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Shimmer diagonal
            LinearGradient(
                colors: [.clear, Color.white.opacity(shimmer ? 0.12 : 0.0), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(22)
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: shimmer)

            // Orbe grande pulsante
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: pulse ? 220 : 185)
                .offset(x: kCardWidth * 0.55, y: totalHeight * 0.35)
                .blur(radius: 10)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulse)

            // Icono decorativo gigante
            Image(systemName: attraction.icon)
                .font(.system(size: 110, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.13))
                .offset(x: kCardWidth * 0.38, y: totalHeight * 0.1)
                .scaleEffect(pulse ? 1.08 : 0.94)
                .rotationEffect(.degrees(pulse ? 6 : -3))
                .animation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true), value: pulse)

            // Partículas chispas
            ForEach(sparkles) { spark in
                Circle()
                    .fill(Color.white.opacity(pulse ? spark.opacity : 0.05))
                    .frame(width: spark.size, height: spark.size)
                    .offset(x: spark.x, y: pulse ? spark.y - 12 : spark.y)
                    .animation(
                        .easeInOut(duration: spark.duration)
                        .repeatForever(autoreverses: true)
                        .delay(spark.delay),
                        value: pulse
                    )
            }

            // ── Contenido ─────────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {

                // Fila superior: back + icono
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                            Text(lm.s(L.challengesBack))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 11).padding(.vertical, 7)
                        .background(Color.white.opacity(0.20))
                        .cornerRadius(20)
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Icono en círculo blanco
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 38, height: 38)
                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                        Image(systemName: attraction.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()

                // Bloque inferior con toda la info
                VStack(alignment: .leading, spacing: 8) {
                    // Badge horario con icono
                    HStack(spacing: 5) {
                        Image(systemName: scheduleIcon(for: attraction.scheduleKey))
                            .font(.system(size: 9, weight: .bold))
                        Text(lm.s(attraction.scheduleKey).uppercased())
                            .font(.system(size: 9, weight: .black))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Color.white.opacity(0.20))
                    .cornerRadius(12)
                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))

                    // Nombre
                    Text(lm.s(attraction.nameKey))
                        .font(.system(size: 21, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        .lineLimit(2)

                    // Separador
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 32, height: 1.5)
                        .cornerRadius(1)

                    // Descripción
                    Text(lm.s(attraction.descriptionKey))
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(2.5)
                        .lineLimit(3)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .frame(width: kCardWidth, height: totalHeight)
        .onAppear {
            pulse   = true
            shimmer = true
        }
    }

    private func scheduleIcon(for key: String) -> String {
        switch key {
        case L.scheduleClimate:      return "cloud.sun.fill"
        case L.scheduleAvailability: return "ticket.fill"
        default:                     return "clock.fill"
        }
    }
}

// MARK: - Partícula de chispa
private struct SparkleParticle: Identifiable {
    let id   = UUID()
    let x:       CGFloat
    let y:       CGFloat
    let size:    CGFloat
    let opacity: Double
    let duration: Double
    let delay:   Double

    static func random(count: Int) -> [SparkleParticle] {
        (0..<count).map { _ in
            SparkleParticle(
                x:        CGFloat.random(in: 30...(kCardWidth - 30)),
                y:        CGFloat.random(in: 20...180),
                size:     CGFloat.random(in: 3...7),
                opacity:  Double.random(in: 0.4...0.75),
                duration: Double.random(in: 1.4...2.8),
                delay:    Double.random(in: 0...1.5)
            )
        }
    }
}

#Preview {
    ScrollView {
        SuggestionsSection(vm: HomeViewModel())
            .environmentObject(LocalizationManager.shared)
            .padding(.top, 20)
    }
    .preferredColorScheme(.dark)
    .background(Color.h3Black)
}
