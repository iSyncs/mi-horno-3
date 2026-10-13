// ChallengesView.swift
import SwiftUI
import UIKit
import Combine


struct ChallengesView: View {
    @EnvironmentObject var vm: ChallengesViewModel
    @EnvironmentObject var lm: LocalizationManager
    @EnvironmentObject var router: AppRouter
    @Environment(\.colorScheme) var scheme
    @Namespace private var animation
    
    @AppStorage("PERFIL_COMPLETADO") var PERFIL_COMPLETADO: Bool = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.h3BG(scheme).ignoresSafeArea()

            backgroundAtmosphere
            dotPattern
                .opacity(scheme == .dark ? 0.14 : 0.07)
                .ignoresSafeArea()

            if let flow = vm.activeFlow {
                switch flow {
                case .quiz(let challenge):
                    ChallengeQuizFlowView(challenge: challenge)
                case .cameraPrep(let challenge):
                    CameraPreparationView(challenge: challenge)
                case .camera(let challenge):
                    ChallengeCameraFlowView(challenge: challenge)
                }
            } else {
                ZStack(alignment: .top) {
                    catalogContent

                    if let expandedZone = vm.expandedZone {
                        ExpandedZoneCard(zone: expandedZone, namespace: animation)
                            .zIndex(2)
                    }
                }
            }
            
            if vm.showBadgeUnlock, let badgeName = vm.newlyUnlockedBadge {
                BadgeUnlockOverlay(badgeName: badgeName) {
                    router.newlyClaimedBadge = badgeName
                    vm.showBadgeUnlock = false
                    vm.newlyUnlockedBadge = nil
                    router.navigateTo(.profile)
                }
                .zIndex(10)
                .transition(.opacity)
            }

            if vm.GENERANDO_PREGUNTA_IA {
                TRIVIA_LOADING_OVERLAY()
                    .zIndex(15)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
            
            if !PERFIL_COMPLETADO {
                PERFILAMIENTO_VIEW()
                    .zIndex(20)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.86), value: vm.expandedZone)
        .animation(.easeInOut(duration: 0.25), value: vm.activeFlow?.id)
        .animation(.spring(), value: vm.showBadgeUnlock)
        .alert("No se pudo generar la trivia", isPresented: Binding(
            get: { vm.ERROR_PREGUNTA_IA != nil },
            set: { VALOR in
                if !VALOR {
                    vm.ERROR_PREGUNTA_IA = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                vm.ERROR_PREGUNTA_IA = nil
            }
        } message: {
            Text(vm.ERROR_PREGUNTA_IA ?? "Intenta de nuevo.")
        }
    }

    private var backgroundAtmosphere: some View {
        ZStack {
            Circle()
                .fill(Color.h3Orange.opacity(scheme == .dark ? 0.18 : 0.11))
                .frame(width: 330, height: 330)
                .blur(radius: 85)
                .offset(x: 160, y: -220)

            Circle()
                .fill(Color(hex: "#5AC8FA").opacity(scheme == .dark ? 0.14 : 0.1))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -150, y: 120)

            Circle()
                .fill(Color(hex: "#30D158").opacity(scheme == .dark ? 0.12 : 0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 65)
                .offset(x: 140, y: 420)
        }
        .ignoresSafeArea()
    }

    private var catalogContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 34)

                VStack(spacing: -36) {
                    ForEach(Array(ChallengeZone.allCases.enumerated()), id: \.element.id) { index, zone in
                        if vm.expandedZone != zone {
                            CollapsedZoneCard(zone: zone, namespace: animation, index: index)
                                .onTapGesture {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.spring(response: 0.62, dampingFraction: 0.84)) {
                                        vm.expandedZone = zone
                                    }
                                }
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 14)
                                .animation(
                                    .spring(response: 0.55, dampingFraction: 0.8)
                                        .delay(0.12 + Double(index) * 0.07),
                                    value: appeared
                                )
                        } else {
                            Color.clear.frame(height: 210)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 120)
            }
        }
        .onAppear { appeared = true }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(lm.s(L.challengesTitle))
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(Color.h3Text(scheme))

                    Text(lm.s(L.challengesDiscover))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.h3Sub(scheme))
                }

                Spacer()
            }

            HStack(spacing: 12) {
                HeaderMetricPill(
                    value: "\(vm.completedChallengesCount)",
                    label: lm.s(L.challengesCompleted),
                    icon: "checkmark.seal.fill",
                    colors: [Color(hex: "#F05A28"), Color(hex: "#FF9B4C")]
                )
                HeaderMetricPill(
                    value: "\(vm.unlockedZonesCount)",
                    label: lm.s(L.challengesZones),
                    icon: "square.grid.2x2.fill",
                    colors: [Color(hex: "#238BFF"), Color(hex: "#84DFFF")]
                )
                HeaderMetricPill(
                    value: "\(Int(vm.overallProgressFraction * 100))%",
                    label: lm.s(L.challengesProgress),
                    icon: "chart.line.uptrend.xyaxis",
                    colors: [Color(hex: "#1DBB64"), Color(hex: "#78FFB3")]
                )
            }
        }
    }

    private var dotPattern: some View {
        Canvas { context, size in
            let dotSize: CGFloat = 2
            let spacing: CGFloat = 24

            for x in stride(from: 0, through: size.width, by: spacing) {
                for y in stride(from: 0, through: size.height, by: spacing) {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(scheme == .dark ? .white : .black))
                }
            }
        }
    }
}

private struct HeaderMetricPill: View {
    @Environment(\.colorScheme) var scheme
    let value: String
    let label: String
    let icon: String
    let colors: [Color]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(scheme == .dark ? Color.h3DarkCard : .white)

            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(colors.first ?? .h3Orange)

                Text(value)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(Color.h3Text(scheme))
                    .minimumScaleFactor(0.75)

                Text(label)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color.h3Text(scheme))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 13)
            .padding(.vertical, 13)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 104)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(scheme == .dark ? .white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.18 : 0.08), radius: 12, y: 6)
    }
}

private struct TRIVIA_LOADING_OVERLAY: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.35)

                VStack(spacing: 6) {
                    Text("Generando trivia")
                        .font(.system(size: 21, weight: .black))
                        .foregroundColor(.white)

                    Text("Preparando 5 desafíos con IA local")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.78))
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 26)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.24), radius: 24, y: 12)
        }
    }
}

private struct ZoneCardGradient: View {
    let zone: ChallengeZone
    let isExpanded: Bool

    private var colors: [Color] {
        switch zone {
        case .general:
            return [Color(hex: "#B93210"), Color(hex: "#F05A28"), Color(hex: "#FF9F0A")]
        case .history:
            return [Color(hex: "#0D47A1"), Color(hex: "#238BFF"), Color(hex: "#00C7FF")]
        case .steelGallery:
            return [Color(hex: "#08733E"), Color(hex: "#1DBB64"), Color(hex: "#30D158")]
        }
    }

    var body: some View {
        if isExpanded {
            staticBackground(drift: .zero, counterDrift: .zero, iconScale: 1)
        } else {
            staticBackground(drift: .zero, counterDrift: .zero, iconScale: 1)
        }
    }

    private func staticBackground(drift: CGSize, counterDrift: CGSize, iconScale: CGFloat) -> some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)

            RadialGradient(
                gradient: Gradient(colors: [.black.opacity(isExpanded ? 0.06 : 0.08), .clear]),
                center: .topLeading,
                startRadius: 10,
                endRadius: isExpanded ? 420 : 220
            )
            .offset(drift)

            AngularGradient(
                colors: [.clear, .black.opacity(0.06), .clear, .black.opacity(0.14), .clear],
                center: .center
            )

            VStack {
                HStack {
                    Circle()
                        .fill(.black.opacity(isExpanded ? 0.08 : 0.07))
                        .frame(width: isExpanded ? 180 : 120, height: isExpanded ? 180 : 120)
                        .blur(radius: 10)
                        .offset(drift)
                    Spacer()
                }
                Spacer()
            }
            .padding(.top, isExpanded ? -20 : 0)
            .padding(.leading, isExpanded ? -25 : 0)

            if !isExpanded {
                Image(systemName: zone.icon)
                    .font(.system(size: 104, weight: .black))
                    .foregroundColor(.black.opacity(0.18))
                    .scaleEffect(iconScale)
                    .offset(x: 120 + counterDrift.width, y: -30 + counterDrift.height)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(.black.opacity(0.14))
                        .frame(width: isExpanded ? 220 : 150, height: isExpanded ? 220 : 150)
                        .blur(radius: 26)
                        .offset(counterDrift)
                }
            }
        }
    }
}

private struct CollapsedZoneCard: View {
    @EnvironmentObject var vm: ChallengesViewModel
    @EnvironmentObject var lm: LocalizationManager

    let zone: ChallengeZone
    let namespace: Namespace.ID
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 54, height: 54)
                        .matchedGeometryEffect(id: "icon_bg_\(zone.id)", in: namespace)
                    Image(systemName: zone.icon)
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .matchedGeometryEffect(id: "icon_\(zone.id)", in: namespace)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(lm.s(zone.titleKey))
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                        .matchedGeometryEffect(id: "title_\(zone.id)", in: namespace)

                    Text("\(vm.xpForZone(zone)) XP • \(vm.rankForZone(zone))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .matchedGeometryEffect(id: "subtitle_\(zone.id)", in: namespace)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                MiniZoneBadge(text: "\(Int(vm.progressForZone(zone) * 100))%", icon: "chart.line.uptrend.xyaxis")
                MiniZoneBadge(text: "\(vm.xpForZone(zone)) XP", icon: "sparkles")
            }
            .matchedGeometryEffect(id: "meta_\(zone.id)", in: namespace)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .frame(height: 196)
        .background(
            ZoneCardGradient(zone: zone, isExpanded: false)
                .matchedGeometryEffect(id: "bg_\(zone.id)", in: namespace)
        )
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: zone.accentColor.opacity(0.34), radius: 26, y: 16)
        .rotation3DEffect(.degrees(index == 1 ? -2 : 1), axis: (x: 1, y: 0, z: 0))
    }
}

private struct MiniZoneBadge: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.16))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

private struct ExpandedZoneCard: View {
    @EnvironmentObject var vm: ChallengesViewModel
    @EnvironmentObject var lm: LocalizationManager

    let zone: ChallengeZone
    let namespace: Namespace.ID

    @State private var MOSTRAR_ALERTA_RESET: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 26) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.18))
                            .frame(width: 72, height: 72)
                            .matchedGeometryEffect(id: "icon_bg_\(zone.id)", in: namespace)
                        Image(systemName: zone.icon)
                            .font(.system(size: 30, weight: .black))
                            .foregroundColor(.white)
                            .matchedGeometryEffect(id: "icon_\(zone.id)", in: namespace)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(lm.s(zone.titleKey))
                            .font(.system(size: 38, weight: .heavy))
                            .foregroundColor(.white)
                            .matchedGeometryEffect(id: "title_\(zone.id)", in: namespace)

                        Text("\(vm.xpForZone(zone)) XP • \(vm.rankForZone(zone))")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white.opacity(0.86))
                            .matchedGeometryEffect(id: "subtitle_\(zone.id)", in: namespace)
                    }

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                            vm.expandedZone = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    MiniZoneBadge(text: "\(Int(vm.progressForZone(zone) * 100))%", icon: "chart.line.uptrend.xyaxis")
                    MiniZoneBadge(text: "\(vm.xpForZone(zone)) XP", icon: "sparkles")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .matchedGeometryEffect(id: "meta_\(zone.id)", in: namespace)

                expandingContentGroup

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    MOSTRAR_ALERTA_RESET = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                        Text("Restaurar Zona")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .alert("Atención", isPresented: $MOSTRAR_ALERTA_RESET) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Restaurar", role: .destructive) {
                        vm.resetZone(zone)
                    }
                } message: {
                    Text("Este botón restaura los desafíos de esta zona al 0% y genera unos nuevos. Tus medallas desbloqueadas no se perderán. ¿Deseas continuar?")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 64)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZoneCardGradient(zone: zone, isExpanded: true)
                .matchedGeometryEffect(id: "bg_\(zone.id)", in: namespace)
        )
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .overlay(alignment: .topTrailing) {
            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(width: 150, height: 1)
                .blur(radius: 1)
                .padding(.top, 30)
                .padding(.trailing, 30)
        }
        .ignoresSafeArea()
    }

    private var expandingContentGroup: some View {
        VStack(spacing: 22) {
            zoneProgressPanel

            HStack(spacing: 16) {
                AnalyticsActionButton(
                    icon: "brain.head.profile",
                    title: zone == .history ? lm.s(L.challengesTriviaNew) : lm.s(L.challengesTrivia),
                    description: vm.ZONA_COMPLETADA(zone) ? "Completaste todos los desafíos" : "Desafíos Infinitos por IA",
                    IS_LOADING: vm.GENERANDO_PREGUNTA_IA,
                    IS_DISABLED: vm.ZONA_COMPLETADA(zone)
                ) {
                    let IMPACTO = UIImpactFeedbackGenerator(style: .medium)
                    IMPACTO.impactOccurred()
                    vm.INICIAR_TRIVIA_IA(ZONA: zone)
                }

                AnalyticsActionButton(
                    icon: "viewfinder.circle.fill",
                    title: lm.s(L.challengesCamera),
                    description: lm.s(L.challengesCameraDesc),
                    IS_LOADING: false,
                    IS_DISABLED: vm.ZONA_COMPLETADA(zone)
                ) {
                    let IMPACTO = UIImpactFeedbackGenerator(style: .medium)
                    IMPACTO.impactOccurred()
                    vm.startNewCameraMission(for: zone)
                }
            }

            if vm.ZONA_COMPLETADA(zone) {
                Text("Completaste todos los desafíos de esta zona.")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.84))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            cameraMissionList

            HStack(spacing: 12) {
                ExpandedFeatureChip(text: lm.s(L.challengesDynamic), icon: "sparkles")
                ExpandedFeatureChip(text: lm.s(L.challengesXPPerChallenge), icon: "bolt.fill")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(.black.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var cameraMissionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lm.s(L.challengesCameraMissions))
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.white)

            VStack(spacing: 10) {
                ForEach(vm.cameraMissions(for: zone)) { mission in
                    CameraMissionRow(
                        mission: mission,
                        isCompleted: vm.isCameraMissionCompleted(mission)
                    ) {
                        vm.startCameraMission(mission)
                    }
                }
            }
        }
    }

    private var zoneProgressPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(lm.s(L.challengesRankProgress))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))
                Spacer()
                Text("\(Int(vm.progressForZone(zone) * 100))%")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.black.opacity(0.24))
                    Capsule()
                        .fill(LinearGradient(colors: [.white.opacity(0.85), .white], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(geo.size.width * vm.progressForZone(zone), 16))
                }
            }
            .frame(height: 14)

            HStack {
                Text("\(lm.s(L.challengesBronzeLabel)) \(zone.xpBronze)")
                Spacer()
                Text("\(lm.s(L.challengesGoldLabel)) \(zone.xpGold)")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white.opacity(0.74))
        }
        .padding(18)
        .background(.black.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct ExpandedFeatureChip: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.1))
        .clipShape(Capsule())
    }
}

private struct CameraMissionRow: View {
    let mission: CameraMission
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : mission.icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(isCompleted ? Color(hex: "#30D158") : .white)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(mission.title)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .strikethrough(isCompleted, color: .white.opacity(0.8))
                    Text(mission.description)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(12)
            .background(.black.opacity(isCompleted ? 0.2 : 0.14))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(isCompleted ? 0.18 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
        .opacity(isCompleted ? 0.72 : 1)
    }
}

private struct AnalyticsActionButton: View {
    let icon: String
    let title: String
    let description: String
    let IS_LOADING: Bool
    let IS_DISABLED: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.16))
                        .frame(width: 66, height: 66)

                    if IS_LOADING {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.82))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 178, alignment: .topLeading)
            .padding(18)
            .background(.black.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(IS_LOADING || IS_DISABLED)
        .opacity((IS_LOADING || IS_DISABLED) ? 0.78 : 1)
    }
}

private struct ChallengeQuizFlowView: View {
    @EnvironmentObject var vm: ChallengesViewModel
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme

    let challenge: ChallengeDefinition

    private var quizSurface: Color {
        scheme == .dark ? Color.h3DarkCard : .white
    }

    private var quizBackground: Color {
        scheme == .dark ? Color.h3Black : Color(hex: "#FAFAFA")
    }

    private var isFinished: Bool {
        vm.currentQuestionIndex >= challenge.questions.count && !challenge.questions.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            quizHeader

            if challenge.questions.isEmpty {
                placeholderQuiz
            } else if isFinished {
                Spacer()
                CompletionCard(
                    title: lm.s(L.challengesComplete),
                    subtitle: String(format: lm.s(L.challengesScore), vm.activeChallengeCorrectCount, challenge.questions.count),
                    score: vm.activeChallengeCorrectCount,
                    total: challenge.questions.count,
                    buttonTitle: lm.s(L.challengesClaimXP),
                    action: { vm.completeChallenge(challenge) }
                )
                .padding(.horizontal, 20)
                Spacer()
            } else if let question = vm.currentQuestion {
                ZStack {
                    quizBackground.ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            questionCard(question: question)

                            VStack(spacing: 14) {
                                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                    QuizOptionButton(
                                        text: option,
                                        index: index,
                                        question: question,
                                        selectedIndex: vm.selectedAnswerIndex,
                                        isChecked: vm.isCurrentQuestionChecked,
                                        action: { vm.selectAnswer(index, questionID: question.id) }
                                    )
                                }
                            }

                            if vm.isCurrentQuestionChecked {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.h3Orange)
                                        .padding(.top, 2)
                                    Text(question.explanation)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.h3Sub(scheme))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(quizSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: .black.opacity(scheme == .dark ? 0.2 : 0.05), radius: 16, y: 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    }
                }

                bottomAction(questionCount: challenge.questions.count)
            }
        }
    }

    private var quizHeader: some View {
        HStack(spacing: 14) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                vm.leaveFlow()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.h3Text(scheme))
                    .frame(width: 42, height: 42)
                    .background(quizSurface)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(scheme == .dark ? 0.18 : 0.05), radius: 12, y: 4)
            }
            .buttonStyle(.plain)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.h3Card2(scheme))
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#E5A102"), Color(hex: "#FF6B00"), Color(hex: "#BD6001")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * vm.quizProgressFraction, 8), height: 10)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 42)

            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#FF6B00"))
                Text("\(challenge.xpReward)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(Color.h3Text(scheme))
            }
            .frame(width: 62, height: 42)
            .background(quizSurface)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(scheme == .dark ? 0.18 : 0.05), radius: 12, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 58)
        .padding(.bottom, 18)
        .background(quizBackground)
    }

    private var placeholderQuiz: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "hourglass.tophalf.filled")
                .font(.system(size: 54))
                .foregroundColor(.h3Orange)
            Text(lm.s(L.challengesLoading))
                .font(.system(size: 24, weight: .black))
                .foregroundColor(Color.h3Text(scheme))
            Text(lm.s(L.challengesLoadingDesc))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.h3Sub(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(quizBackground)
    }

    private func questionCard(question: ChallengeQuestion) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(String(format: lm.s(L.challengesQuestionLabel), vm.currentQuestionIndex + 1, challenge.questions.count))
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(Color(hex: "#BD6001"))

                Text(question.text)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(Color.h3Text(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(quizSurface)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(scheme == .dark ? 0.22 : 0.06), radius: 18, y: 10)
    }

    private func bottomAction(questionCount: Int) -> some View {
        VStack(spacing: 0) {
            Button {
                if vm.isCurrentQuestionChecked {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    vm.continueQuiz(totalQuestions: questionCount, challenge: challenge)
                } else {
                    let isCorrect = (vm.selectedAnswerIndex == vm.currentQuestion?.correctIndex)
                    if isCorrect {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                    vm.checkCurrentAnswer()
                }
            } label: {
                Text(vm.isCurrentQuestionChecked
                     ? (vm.currentQuestionIndex == questionCount - 1 ? lm.s(L.challengesSeeResults) : lm.s(L.challengesContinue))
                     : lm.s(L.challengesCheck))
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.white)
                .tracking(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#FF6B00"), Color(hex: "#BD6001")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: Color(hex: "#FF6B00").opacity(0.25), radius: 16, y: 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 24)
            .disabled(!vm.hasAnsweredCurrentQuestion)
            .opacity(vm.hasAnsweredCurrentQuestion ? 1 : 0.45)
        }
        .background(quizBackground)
    }
}

private struct QuizOptionButton: View {
    @Environment(\.colorScheme) var scheme

    let text: String
    let index: Int
    let question: ChallengeQuestion
    let selectedIndex: Int?
    let isChecked: Bool
    let action: () -> Void

    private var isSelected: Bool { selectedIndex == index }
    private var isCorrect: Bool { question.correctIndex == index }

    private var baseSurface: Color {
        scheme == .dark ? Color.h3DarkCard : .white
    }

    private var backgroundColor: Color {
        guard let selectedIndex else { return Color.h3Card2(scheme).opacity(scheme == .dark ? 0.9 : 0.45) }
        guard isChecked else { return isSelected ? baseSurface : Color.h3Card2(scheme).opacity(scheme == .dark ? 0.9 : 0.45) }
        if isCorrect { return Color(hex: "#30D158").opacity(scheme == .dark ? 0.22 : 0.15) }
        if selectedIndex == index { return Color(hex: "#FF453A").opacity(scheme == .dark ? 0.22 : 0.15) }
        return Color.h3Card2(scheme).opacity(scheme == .dark ? 0.9 : 0.45)
    }

    private var textColor: Color {
        guard let selectedIndex else { return Color.h3Text(scheme) }
        guard isChecked else { return Color.h3Text(scheme) }
        if isCorrect { return scheme == .dark ? Color(hex: "#7DFFAF") : Color(hex: "#167A39") }
        if selectedIndex == index { return scheme == .dark ? Color(hex: "#FF9C95") : Color(hex: "#C53228") }
        return Color.h3Sub(scheme)
    }

    private var numberBackground: Color {
        guard let selectedIndex else { return Color.gray.opacity(0.18) }
        guard isChecked else { return isSelected ? Color(hex: "#FF6B00") : Color.gray.opacity(0.18) }
        if isCorrect { return Color(hex: "#30D158") }
        if selectedIndex == index { return Color(hex: "#FF453A") }
        return Color.gray.opacity(0.18)
    }

    private var outlineColor: Color {
        guard let selectedIndex else { return .clear }
        guard isChecked else { return isSelected ? Color(hex: "#FF6B00") : .clear }
        if isCorrect { return Color(hex: "#30D158") }
        if selectedIndex == index { return Color(hex: "#FF453A") }
        return .clear
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 14) {
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor((selectedIndex == nil || (!isChecked && !isSelected)) ? Color.h3Sub(scheme) : .white)
                    .frame(width: 38, height: 38)
                    .background(numberBackground)
                    .clipShape(Circle())

                Text(text)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if isChecked, selectedIndex != nil, isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#30D158"))
                } else if isChecked, isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#FF453A"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(outlineColor, lineWidth: outlineColor == .clear ? 0 : 2)
            )
            .shadow(color: outlineColor == .clear ? .clear : outlineColor.opacity(0.16), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isChecked)
    }
}

fileprivate enum ImagePickerRoute: Identifiable {
    case camera
    case library

    var id: String {
        switch self {
        case .camera: return "camera"
        case .library: return "library"
        }
    }

    var sourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: return .camera
        case .library: return .photoLibrary
        }
    }
}

private struct ChallengeCameraFlowView: View {
    @EnvironmentObject var vm: ChallengesViewModel
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme

    let challenge: ChallengeDefinition

    enum CameraStep: Equatable {
        case instruction, scanning, analyzing, result(Bool)
    }

    @State private var currentStep: CameraStep = .instruction
    @State private var scanOffset: CGFloat = -140
    @State private var pulse = false
    
    // Nativas
    @State private var pickerRoute: ImagePickerRoute? = nil
    @State private var takenImage: UIImage? = nil
    
    // Cronómetro
    @State private var TIEMPO_RESTANTE: CGFloat = 60.0
    @State private var MOSTRAR_ALERTA_TIEMPO = false
    let CRONOMETRO = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.h3BG(scheme).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 50)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                        Capsule()
                            .fill(TIEMPO_RESTANTE > 15 ? challenge.zone.accentColor : Color.red)
                            .frame(width: max(0, geo.size.width * (TIEMPO_RESTANTE / 60.0)))
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .animation(.linear(duration: 0.1), value: TIEMPO_RESTANTE)
                
                Spacer()
                
                contentForStep
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
            
            if case .analyzing = currentStep {
                loadingOverlay
            }
        }
        .onAppear {
            vm.isObjectDetected = false
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                scanOffset = 140
                pulse = true
            }
        }
        .fullScreenCover(item: $pickerRoute) { route in
            ImagePicker(image: $takenImage, route: $pickerRoute, sourceType: route.sourceType)
                .ignoresSafeArea()
        }
        .onChange(of: takenImage) { newImage in
            if let img = newImage {
                simulateAnalysis(with: img)
            }
        }
        .onReceive(CRONOMETRO) { _ in
            guard currentStep == .instruction || currentStep == .scanning else { return }
            guard !MOSTRAR_ALERTA_TIEMPO else { return }
            
            if TIEMPO_RESTANTE > 0 {
                TIEMPO_RESTANTE -= 0.1
                if TIEMPO_RESTANTE <= 0 {
                    TIEMPO_RESTANTE = 0
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    pickerRoute = nil // Cierra la cámara si está abierta
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        MOSTRAR_ALERTA_TIEMPO = true
                    }
                }
            }
        }
        .alert("¡Terminó tu tiempo!", isPresented: $MOSTRAR_ALERTA_TIEMPO) {
            Button("Aceptar", role: .cancel) {
                vm.leaveFlow()
            }
        } message: {
            Text("No lograste completar el desafío a tiempo. ¡Inténtalo de nuevo!")
        }
    }

    @ViewBuilder
    private var contentForStep: some View {
        switch currentStep {
        case .instruction, .scanning:
            instructionCard
        case .analyzing:
            EmptyView()
        case .result(let success):
            resultCard(success: success)
        }
    }

    private var topBar: some View {
        HStack {
            Button { 
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                vm.leaveFlow() 
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.h3Text(scheme))
                    .frame(width: 36, height: 36)
                    .background(Color.h3Card2(scheme))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(lm.s(L.challengesCameraLabel))
                .font(.system(size: 17, weight: .black))
                .foregroundColor(Color.h3Text(scheme))

            Spacer()

            Circle()
                .fill(challenge.zone.accentColor)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(challenge.zone.accentColor.opacity(0.4), lineWidth: 6))
                .scaleEffect(pulse ? 1.1 : 0.9)
        }
    }

    private var instructionCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(challenge.zone.accentColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: vm.activeCameraMission?.icon ?? challenge.icon)
                    .font(.system(size: 34))
                    .foregroundColor(challenge.zone.accentColor)
            }

            VStack(spacing: 8) {
                Text(lm.s(L.challengesMissionFound))
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(challenge.zone.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(challenge.zone.accentColor.opacity(0.1))
                    .clipShape(Capsule())

                Text(vm.activeCameraMission?.title ?? challenge.title)
                    .font(.system(size: 24, weight: .black))
                    .multilineTextAlignment(.center)
                
                Text(vm.activeCameraMission?.description ?? challenge.subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(lm.s(L.challengesCameraChoiceHint))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.h3Sub(scheme).opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }

            VStack(spacing: 10) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    pickerRoute = .camera
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 15, weight: .black))
                        Text(lm.s(L.challengesOpenCamera))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(challenge.zone.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                .opacity(UIImagePickerController.isSourceTypeAvailable(.camera) ? 1 : 0.5)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    pickerRoute = .library
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 15, weight: .black))
                        Text(lm.s(L.challengesOpenLibrary))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(challenge.zone.accentColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(challenge.zone.accentColor.opacity(scheme == .dark ? 0.16 : 0.11))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(challenge.zone.accentColor.opacity(0.35), lineWidth: 1)
                    )
                }
            }
        }
        .padding(24)
        .background(scheme == .dark ? Color.h3DarkCard : .white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                
                Text(lm.s(L.challengesAnalyzing))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    private func resultCard(success: Bool) -> some View {
        VStack(spacing: 24) {
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(success ? Color(hex: "#30D158") : .red)

            VStack(spacing: 8) {
                Text(success ? lm.s(L.challengesSuccess) : lm.s(L.challengesNotTarget))
                    .font(.system(size: 22, weight: .black))
                
                Text(success ? lm.s(L.challengesSuccessMsg) : lm.s(L.challengesFailMsg))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }

            Button {
                if success {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    vm.completeChallenge(challenge)
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation { currentStep = .instruction }
                    takenImage = nil
                }
            } label: {
                Text(success ? String(format: lm.s(L.challengesClaimXPFmt), challenge.xpReward) : lm.s(L.challengesRetryBtn))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(success ? Color(hex: "#30D158") : Color(hex: "#FF453A"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .padding(24)
        .background(scheme == .dark ? Color.h3DarkCard : .white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }

    private func simulateAnalysis(with image: UIImage) {
        withAnimation { currentStep = .analyzing }
        
        let startTime = Date()
        vm.visionService.classify(image: image) {
            let elapsed = Date().timeIntervalSince(startTime)
            let remainingWait = max(0, 1.5 - elapsed)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + remainingWait) {
                let isCorrect = vm.isObjectDetected
                withAnimation(.spring()) {
                    currentStep = .result(isCorrect)
                }
            }
        }
    }
}

// MARK: - ImagePicker Wrapper
fileprivate struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var route: ImagePickerRoute?
    let sourceType: UIImagePickerController.SourceType
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.route = nil
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.route = nil
        }
    }
}

private struct CameraInfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .black))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.24))
        .clipShape(Capsule())
    }
}

private struct CameraStatCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct FocusCorner: View {
    let rotation: Angle
    let color: Color

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 24))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 24, y: 0))
        }
        .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        .frame(width: 24, height: 24)
        .rotationEffect(rotation)
    }
}

#Preview {
    let vm = ChallengesViewModel()
    return ChallengesView()
        .environmentObject(vm)
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
