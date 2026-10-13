//
//  WrappedView.swift
//  Mi Horno 3
//

import SwiftUI
import UIKit

// ─────────────────────────────────────────────
// MARK: - Haptics helper
// ─────────────────────────────────────────────

private enum Haptic {
    static func soft()    { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func medium()  { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy()   { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func rigid()   { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }

    /// Patrón de fiesta: doble golpe con leve delay
    static func celebrate() {
        medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { heavy() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) { success() }
    }
}

// ─────────────────────────────────────────────
// MARK: - WrappedView
// ─────────────────────────────────────────────

struct WrappedView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lm: LocalizationManager
    @StateObject private var vm: WrappedViewModel

    @GestureState private var dragX: CGFloat = 0
    @State private var direction: Int = 1

    @State private var showConfetti  = false
    @State private var storyProgress: CGFloat = 0

    init(answersCount: Int, correctCount: Int, unlockedMedals: Int, totalMedals: Int, badges: [GamificationBadge]) {
        _vm = StateObject(wrappedValue: WrappedViewModel(
            answersCount: answersCount, correctCount: correctCount,
            unlockedMedals: unlockedMedals, totalMedals: totalMedals,
            badges: badges
        ))
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                storyProgressBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 14)

                cardStack
                    .padding(.horizontal, 16)

                bottomControls
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
            }

            // ── Confeti — NUNCA tocar esto
            if showConfetti {
                ConfettiLayer()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .onAppear {
            if lm.isReady { vm.buildCards(lm: lm) }
            vm.startSession()
            animateStoryBar()
            Haptic.soft()
        }
        .onChange(of: lm.isReady) { ready in if ready { vm.buildCards(lm: lm) } }
        .onChange(of: vm.currentIndex) { _ in
            animateStoryBar()
            if vm.isLastCard {
                Haptic.celebrate()
                withAnimation(.easeIn(duration: 0.5).delay(0.35)) { showConfetti = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
                    withAnimation { showConfetti = false }
                }
            }
        }
        .onDisappear { vm.endSession() }
    }

    // ─────────────────────────────────────────
    // MARK: Fondo
    // ─────────────────────────────────────────

    private var backgroundLayer: some View {
        ZStack {
            if !vm.cards.isEmpty {
                vm.cards[vm.currentIndex].color
                    .opacity(0.35)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.65), value: vm.currentIndex)
            }
            Color.h3Black.opacity(0.78).ignoresSafeArea()

            // Bokeh que cambia con el card
            Circle()
                .fill(RadialGradient(
                    colors: [
                        (vm.cards.isEmpty ? Color.h3Orange : vm.cards[vm.currentIndex].accentColor).opacity(0.20),
                        .clear
                    ],
                    center: .center, startRadius: 0, endRadius: 200
                ))
                .frame(width: 360, height: 360)
                .offset(x: 90, y: -180)
                .blur(radius: 28)
                .animation(.easeInOut(duration: 0.8), value: vm.currentIndex)
                .ignoresSafeArea()
        }
    }

    // ─────────────────────────────────────────
    // MARK: Barra superior
    // ─────────────────────────────────────────

    private var topBar: some View {
        HStack {
            Button {
                Haptic.soft()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: 32, height: 32)
                    .background(.white.opacity(0.12))
                    .clipShape(Circle())
            }
            Spacer()
            Text(lm.s(L.wrappedTitle))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.70))
                .kerning(0.3)
            Spacer()
            Circle().fill(Color.clear).frame(width: 32, height: 32)
        }
    }

    // ─────────────────────────────────────────
    // MARK: Barra progreso tipo Stories
    // ─────────────────────────────────────────

    private var storyProgressBar: some View {
        HStack(spacing: 5) {
            ForEach(0..<vm.cards.count, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.22))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white)
                            .frame(width: fillWidth(for: i, total: geo.size.width))
                    }
                }
                .frame(height: 3)
                .animation(.easeInOut(duration: 0.35), value: vm.currentIndex)
            }
        }
    }

    private func fillWidth(for index: Int, total: CGFloat) -> CGFloat {
        if index < vm.currentIndex { return total }
        if index > vm.currentIndex { return 0 }
        return total * storyProgress
    }

    private func animateStoryBar() {
        storyProgress = 0
        withAnimation(.linear(duration: 0.38).delay(0.14)) { storyProgress = 1.0 }
    }

    // ─────────────────────────────────────────
    // MARK: Stack de tarjetas
    // ─────────────────────────────────────────

    @ViewBuilder
    private var cardStack: some View {
        if !vm.cards.isEmpty {
            WrappedCardView(card: vm.cards[vm.currentIndex], badges: vm.badges)
                .id(vm.currentIndex)
                .offset(x: dragX * 0.42)
                .rotation3DEffect(
                    .degrees(Double(dragX) / 22),
                    axis: (x: 0.06, y: 1, z: 0),
                    perspective: 0.35
                )
                .scaleEffect(1.0 - abs(dragX) / 3000)
                .transition(.asymmetric(
                    insertion: .modifier(
                        active:   WrapTransition(offset: 360 * CGFloat(direction), scale: 0.82, opacity: 0, blur: 8, rotation: -9 * Double(direction)),
                        identity: WrapTransition(offset: 0, scale: 1, opacity: 1, blur: 0, rotation: 0)
                    ),
                    removal: .modifier(
                        active:   WrapTransition(offset: -360 * CGFloat(direction), scale: 0.82, opacity: 0, blur: 8, rotation: 9 * Double(direction)),
                        identity: WrapTransition(offset: 0, scale: 1, opacity: 1, blur: 0, rotation: 0)
                    )
                ))
                .gesture(
                    DragGesture()
                        .updating($dragX) { val, state, _ in state = val.translation.width }
                        .onEnded { val in
                            let t = val.translation.width; let v = val.velocity.width
                            if      t < -50 || v < -400 { navigate(forward: true) }
                            else if t >  50 || v >  400 { navigate(forward: false) }
                        }
                )
                .simultaneousGesture(TapGesture().onEnded { navigate(forward: true) })
        }
    }

    // ─────────────────────────────────────────
    // MARK: Controles inferiores
    // ─────────────────────────────────────────

    private var bottomControls: some View {
        HStack(spacing: 16) {
            Button {
                Haptic.soft()
                navigate(forward: false)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(vm.isFirstCard ? .white.opacity(0.18) : .white.opacity(0.85))
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(vm.isFirstCard ? 0.04 : 0.14))
                    .clipShape(Circle())
            }
            .disabled(vm.isFirstCard)
            .animation(.spring(response: 0.3), value: vm.isFirstCard)

            Spacer()

            Text("\(vm.currentIndex + 1) / \(vm.cards.count)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: vm.currentIndex)

            Spacer()

            Button {
                if vm.isLastCard { Haptic.medium(); dismiss() }
                else { navigate(forward: true) }
            } label: {
                HStack(spacing: 6) {
                    Text(vm.isLastCard ? lm.s(L.wrappedClose) : lm.s(L.wrappedNext))
                        .font(.system(size: 14, weight: .bold))
                    if !vm.isLastCard {
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                    }
                }
                .foregroundColor(.black)
                .padding(.horizontal, 18)
                .frame(height: 46)
                .background(.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.16), radius: 8, y: 3)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: vm.isLastCard)
        }
    }

    // ─────────────────────────────────────────
    // MARK: Navegación + haptics
    // ─────────────────────────────────────────

    private func navigate(forward: Bool) {
        guard forward ? !vm.isLastCard : !vm.isFirstCard else { return }

        // Haptic: avanzar = medium, regresar = soft
        forward ? Haptic.medium() : Haptic.soft()

        let c = vm.cards[vm.currentIndex]
        if [.challenges, .accuracy, .medals, .nickname].contains(c.type) {
            vm.registerRoom(name: c.title.replacingOccurrences(of: "\n", with: " "), durationSeconds: 10)
        }

        direction = forward ? 1 : -1
        withAnimation(.spring(response: 0.44, dampingFraction: 0.74)) {
            if forward { vm.next() } else { vm.previous() }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Transición con blur
// ─────────────────────────────────────────────

struct WrapTransition: ViewModifier {
    let offset: CGFloat; let scale: CGFloat
    let opacity: Double; let blur: CGFloat; let rotation: Double

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .scaleEffect(scale)
            .opacity(opacity)
            .blur(radius: blur)
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
    }
}

// ─────────────────────────────────────────────
// MARK: - Confeti (NO MODIFICAR)
// ─────────────────────────────────────────────

struct ConfettiLayer: View {
    @State private var pieces: [ConfettiPiece] = ConfettiPiece.generate(count: 60)
    @State private var fallen = false

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { p in
                RoundedRectangle(cornerRadius: p.size * 0.25)
                    .fill(p.color)
                    .frame(width: p.size, height: p.size * 0.5)
                    .rotationEffect(.degrees(fallen ? p.finalRotation : p.startRotation))
                    .position(x: p.x * geo.size.width, y: fallen ? geo.size.height + 40 : -20)
                    .opacity(fallen ? 0 : 0.9)
                    .animation(.easeIn(duration: p.duration).delay(p.delay), value: fallen)
            }
        }
        .ignoresSafeArea()
        .onAppear { fallen = true }
    }
}

struct ConfettiPiece: Identifiable {
    let id            = UUID()
    let x:            CGFloat
    let size:         CGFloat
    let color:        Color
    let delay:        Double
    let duration:     Double
    let startRotation: Double
    let finalRotation: Double

    static let colors: [Color] = [
        .h3Orange, Color(hex: "#FFD60A"), Color(hex: "#30D158"),
        Color(hex: "#0A84FF"), Color(hex: "#BF5AF2"), Color(hex: "#FF453A"),
        .white, Color(hex: "#FF9F0A")
    ]

    static func generate(count: Int) -> [ConfettiPiece] {
        (0..<count).map { _ in
            ConfettiPiece(
                x:             CGFloat.random(in: 0...1),
                size:          CGFloat.random(in: 7...16),
                color:         colors.randomElement()!,
                delay:         Double.random(in: 0...0.8),
                duration:      Double.random(in: 1.2...2.4),
                startRotation: Double.random(in: -45...45),
                finalRotation: Double.random(in: 200...520)
            )
        }
    }
}

#Preview {
    WrappedView(answersCount: 8, correctCount: 6, unlockedMedals: 4, totalMedals: 6, badges: [])
        .environmentObject(LocalizationManager.shared)
}
