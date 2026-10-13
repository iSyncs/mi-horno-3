// ExploreSection.swift
// Sección Explora rediseñada — animaciones de entrada, cards grandes y dinámicas
// NOTA: Este archivo reemplaza tanto ExploreSection.swift como ExploreButton.swift
//       → Elimina ExploreButton.swift del proyecto después de reemplazar este archivo

import SwiftUI

// ExploreItem es internal (no private) para evitar ambigüedad con el compilador
struct ExploreItem: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: String
    let descKey: String
    let color: Color
    let action: () -> Void
}

struct ExploreSection: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme
    @Binding var showAssistant: Bool
    @Binding var showSensory: Bool

    @State private var appeared = false

    private var items: [ExploreItem] {[
        ExploreItem(
            icon: "camera.viewfinder",
            titleKey: L.homeExploreAssistant,
            descKey: L.homeExploreAssistantDesc,
            color: Color.h3Orange,
            action: { showAssistant = true }
        ),
        ExploreItem(
            icon: "trophy.fill",
            titleKey: L.homeExploreChallenges,
            descKey: L.homeExploreChallengesDesc,
            color: Color(hex: "#FF9F0A"),
            action: { router.navigateTo(.challenges) }
        ),
        ExploreItem(
            icon: "map.fill",
            titleKey: L.homeExploreMap,
            descKey: L.homeExploreMapDesc,
            color: Color(hex: "#30D158"),
            action: { router.navigateTo(.map) }
        ),
        ExploreItem(
            icon: "brain.head.profile",
            titleKey: L.homeExploreSensory,
            descKey: L.homeExploreSensoryDesc,
            color: Color(hex: "#BF5AF2"),
            action: { showSensory = true }
        ),
    ]}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text(lm.s(L.homeExploreTitle))
                .font(.system(size: 20, weight: .black))
                .foregroundColor(Color.h3Text(scheme))
                .padding(.horizontal, 24)
                .offset(y: appeared ? 0 : 12)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: appeared)

            VStack(spacing: 12) {
                // Card grande — Asistente
                if let featured = items.first {
                    ExploreLargeCard(item: featured, lm: lm)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.10), value: appeared)
                }

                // 3 cards medianas
                HStack(spacing: 12) {
                    ForEach(Array(items.dropFirst().enumerated()), id: \.element.id) { idx, item in
                        ExploreMediumCard(item: item, lm: lm)
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.75)
                                    .delay(0.15 + Double(idx) * 0.06),
                                value: appeared
                            )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 32)
        .onAppear { if !appeared { appeared = true } }
    }
}

// MARK: - Large Card (Asistente)
struct ExploreLargeCard: View {
    let item: ExploreItem
    let lm: LocalizationManager
    @Environment(\.colorScheme) var scheme
    @State private var pulse = false

    var body: some View {
        Button(action: item.action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [item.color, item.color.opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 165)

                // Orbes animados
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: pulse ? 160 : 140)
                    .offset(x: 240, y: -20)
                    .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: pulse)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: pulse ? 100 : 85)
                    .offset(x: 260, y: 30)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.6), value: pulse)

                // Icono decorativo
                Image(systemName: item.icon)
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(.white.opacity(0.22))
                    .offset(x: 220, y: -58)
                    .scaleEffect(pulse ? 1.04 : 0.97)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulse)

                // Texto
                VStack(alignment: .leading, spacing: 4) {
                    Text(lm.s(item.titleKey))
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                    Text(lm.s(item.descKey))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .shadow(color: item.color.opacity(0.35), radius: 14, x: 0, y: 6)
        .onAppear { pulse = true }
    }
}

// MARK: - Medium Card
struct ExploreMediumCard: View {
    let item: ExploreItem
    let lm: LocalizationManager
    @Environment(\.colorScheme) var scheme
    @State private var pulse = false

    var body: some View {
        Button(action: item.action) {
            ZStack(alignment: .bottomLeading) {
                // Mismo gradiente que el Large Card
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [item.color, item.color.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Orbe decorativo animado (esquina superior derecha)
                Circle()
                    .fill(Color.white.opacity(0.09))
                    .frame(width: pulse ? 80 : 68)
                    .offset(x: 50, y: -40)
                    .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: pulse)

                // Icono flotante semitransparente de fondo
                Image(systemName: item.icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.white.opacity(0.18))
                    .offset(x: 48, y: -25)
                    .scaleEffect(pulse ? 1.05 : 0.96)
                    .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: pulse)

                // Icono + texto abajo a la izquierda
                VStack(alignment: .leading, spacing: 3) {
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(lm.s(item.titleKey))
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: item.color.opacity(0.38), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .onAppear { pulse = true }
    }
}

#Preview {
    ScrollView {
        ExploreSection(showAssistant: .constant(false), showSensory: .constant(false))
            .padding(.top, 20)
    }
    .environmentObject(AppRouter())
    .environmentObject(LocalizationManager.shared)
    .preferredColorScheme(.dark)
    .background(Color.h3Black)
}
