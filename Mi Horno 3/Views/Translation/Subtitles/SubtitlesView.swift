// SubtitlesView.swift
// Subtítulos en vivo — rediseño minimalista estilo Gemini

import SwiftUI
import Combine
import AVFoundation
import Speech
import Vision
import VisionKit
import Translation
import NaturalLanguage

// ─────────────────────────────────────────────

// MARK: - SubtitlesView
// ─────────────────────────────────────────────
struct SubtitlesView: View {
    @EnvironmentObject var lm: LocalizationManager
    @ObservedObject var vm: TranslationViewModel

    // Estado del micrófono
    @Environment(\.colorScheme) var scheme
    @State private var isActive = false          // true = grabando
    @State private var buttonScale: CGFloat = 1.0

    // Efecto Aladdin — reveal letra a letra
    @State private var displayedText: String = ""
    @State private var revealTimer: Timer? = nil
    @State private var previousRaw: String = ""

    // Fade out al detectar pausa natural
    @State private var isFading = false
    @State private var sentenceTimer: Timer? = nil

    // Marco — aparece al activar mic
    @State private var frameVisible = false
    @State private var frameScale: CGFloat = 0.94

    // Animación Gemini del botón
    @State private var geminiPhase: CGFloat = 0
    @State private var geminiOpacity: Double = 0
    @State private var geminiScale: CGFloat = 1.0
    @State private var ripple1: CGFloat = 0
    @State private var ripple2: CGFloat = 0
    @State private var ripple3: CGFloat = 0

    private let orange = Color.h3Orange

    var body: some View {
        ZStack {
            Color.h3BG(scheme).ignoresSafeArea()

            // Glow de fondo — aparece al activar
            if isActive {
                RadialGradient(
                    colors: [orange.opacity(0.10), .clear],
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
                .transition(.opacity)
                .animation(.easeInOut(duration: 1.2), value: isActive)
            }

            VStack(spacing: 0) {

                // ── Top bar ──────────────────────────────────────
                HStack {
                    Button {
                        dismissSubtitles()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.h3Sub(scheme))
                            .frame(width: 36, height: 36)
                            .background(Color.h3Card2(scheme))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 20)

                // ── Marco de texto ───────────────────────────────
                ZStack {
                    // Fondo del marco
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.h3Card(scheme))

                    // Borde animado — gradiente rotativo cuando escucha
                    if isActive {
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        orange.opacity(0.7),
                                        Color(hex: "#FF9A5C").opacity(0.4),
                                        orange.opacity(0.1),
                                        orange.opacity(0.7)
                                    ],
                                    center: .center,
                                    angle: .degrees(geminiPhase)
                                ),
                                lineWidth: 1.5
                            )
                            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: geminiPhase)
                    } else {
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    }

                    // Contenido del marco
                    if !frameVisible {
                        // Estado inicial — ícono placeholder
                        VStack(spacing: 14) {
                            Image(systemName: "captions.bubble.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color.h3Sub(scheme).opacity(0.15))
                            Text(lm.s(L.translationPlaceholder))
                                .font(.system(size: 14))
                                .foregroundColor(Color.h3Sub(scheme).opacity(0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .transition(.opacity)

                    } else {
                        // Marco activo
                        VStack(alignment: .leading, spacing: 0) {

                            // Label top
                            HStack(spacing: 7) {
                                // Barra de acento naranja
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(orange)
                                    .frame(width: 3, height: 13)

                                Text(lm.s(L.translationSubtitlesTitle).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(orange)
                                    .tracking(0.7)

                                Spacer()

                                // Barras de audio estilo ecualizador
                                if isActive {
                                    AudioBarsView(isActive: isActive, color: orange)
                                }
                            }
                            .padding(.bottom, 18)

                            // Texto traducido con efecto Aladdin
                            if displayedText.isEmpty {
                                Text(isActive ? "…" : "")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.h3Sub(scheme).opacity(0.3))
                                    .transition(.opacity)
                            } else {
                                Text(displayedText)
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(isFading ? Color.h3Text(scheme).opacity(0.12) : Color.h3Text(scheme))
                                    .lineSpacing(5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .animation(.easeOut(duration: 0.35), value: isFading)
                                    .transition(.opacity)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .transition(.opacity)
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 20)
                .scaleEffect(frameScale)
                .opacity(frameVisible ? 1 : 0.4)
                .animation(.spring(response: 0.5, dampingFraction: 0.78), value: frameVisible)
                .animation(.spring(response: 0.5, dampingFraction: 0.78), value: frameScale)

                Spacer(minLength: 24)

                // ── Botón mic estilo Gemini ──────────────────────
                VStack(spacing: 14) {
                    ZStack {
                        // Ripples concéntricos — se expanden desde el centro
                        if isActive {
                            Circle()
                                .stroke(orange.opacity(0.25 * (1 - ripple1)), lineWidth: 1.5)
                                .frame(width: 72 + ripple1 * 50, height: 72 + ripple1 * 50)
                                .animation(
                                    .easeOut(duration: 1.6).repeatForever(autoreverses: false),
                                    value: ripple1
                                )
                            Circle()
                                .stroke(orange.opacity(0.18 * (1 - ripple2)), lineWidth: 1)
                                .frame(width: 72 + ripple2 * 70, height: 72 + ripple2 * 70)
                                .animation(
                                    .easeOut(duration: 1.6).delay(0.4).repeatForever(autoreverses: false),
                                    value: ripple2
                                )
                            Circle()
                                .stroke(orange.opacity(0.10 * (1 - ripple3)), lineWidth: 0.5)
                                .frame(width: 72 + ripple3 * 90, height: 72 + ripple3 * 90)
                                .animation(
                                    .easeOut(duration: 1.6).delay(0.8).repeatForever(autoreverses: false),
                                    value: ripple3
                                )
                        }

                        // Fondo del botón con gradiente Gemini
                        Button {
                            handleMicTap()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        isActive
                                        ? AnyShapeStyle(
                                            AngularGradient(
                                                colors: [orange, Color(hex: "#FF9A5C"), orange],
                                                center: .center,
                                                angle: .degrees(geminiPhase)
                                            )
                                          )
                                        : AnyShapeStyle(
                                            LinearGradient(
                                                colors: [Color.h3OrangeLight, orange],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                          )
                                    )
                                    .frame(width: 72, height: 72)
                                    .shadow(
                                        color: orange.opacity(isActive ? 0.6 : 0.35),
                                        radius: isActive ? 22 : 12
                                    )
                                    .scaleEffect(geminiScale)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isActive)

                                Image(systemName: isActive ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(.white)
                                    .animation(.easeInOut(duration: 0.2), value: isActive)
                            }
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(buttonScale)
                    }
                    .frame(width: 160, height: 160)

                    Text(isActive ? lm.s(L.translationMicListening) : lm.s(L.translationMicPress))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.h3Sub(scheme).opacity(0.5))
                        .animation(.easeInOut(duration: 0.2), value: isActive)
                }
                .padding(.bottom, 52)

                if vm.permissionDenied {
                    Text(lm.s(L.translationMicDenied))
                        .font(.system(size: 12)).foregroundColor(.red).padding(.bottom, 12)
                }
            }
        }
        .onChange(of: vm.translatedTranscript) { newText in
            guard !newText.isEmpty, isActive else { return }
            handleNewTranslation(newText)
        }
        .onDisappear {
            cleanUp()
        }
    }

    // MARK: - Acciones

    private func handleMicTap() {
        // Haptic
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Bounce del botón
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { buttonScale = 0.85 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { buttonScale = 1.0 }
        }

        if isActive {
            stopListening()
        } else {
            startListening()
        }
    }

    private func startListening() {
        isActive = true

        // Mostrar marco con animación
        withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
            frameVisible = true
            frameScale = 1.0
        }

        // Iniciar gradiente rotativo
        geminiPhase = 0
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            geminiPhase = 360
        }

        // Iniciar botón pulsante
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            geminiScale = 1.06
        }

        // Iniciar ripples
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            ripple1 = 1; ripple2 = 1; ripple3 = 1
        }

        // Limpiar estado
        displayedText = ""
        previousRaw = ""
        isFading = false

        // Setear activeFeature antes de llamar startSubtitleListening
        // (el guard interno lo requiere para no salir inmediatamente)
        vm.activeFeature = .subtitles
        vm.startSubtitleListening()
    }

    private func stopListening() {
        isActive = false
        geminiPhase = 0
        geminiScale = 1.0
        ripple1 = 0; ripple2 = 0; ripple3 = 0

        // Marco se contrae un poco pero queda visible con el último texto
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            frameScale = 0.98
        }

        revealTimer?.invalidate()
        sentenceTimer?.invalidate()
        vm.stopAudio()
    }

    private func dismissSubtitles() {
        cleanUp()
        vm.stopAudio()
        vm.activeFeature = .none
    }

    private func cleanUp() {
        revealTimer?.invalidate()
        sentenceTimer?.invalidate()
        isActive = false
        geminiScale = 1.0
        ripple1 = 0; ripple2 = 0; ripple3 = 0
    }

    // MARK: - Manejo inteligente del texto traducido

    private func handleNewTranslation(_ newText: String) {
        // Cancela timer de pausa — llegó texto nuevo
        sentenceTimer?.invalidate()
        isFading = false

        // El reconocedor de voz va corrigiendo palabras anteriores constantemente.
        // Estrategia: encontrar cuántos caracteres del inicio coinciden con lo ya mostrado
        // y solo animar los caracteres realmente nuevos — nunca reescribir lo visible.
        let commonLength = commonPrefixLength(displayedText, newText)

        if commonLength == displayedText.count {
            // El texto mostrado sigue siendo válido — solo revelar los nuevos al final
            revealChars(newText, from: displayedText.count)
        } else {
            // El reconocedor corrigió algo ya mostrado — actualizar silenciosamente
            // solo la parte corregida y continuar desde ahí sin animación brusca
            revealTimer?.invalidate()
            displayedText = String(newText.prefix(commonLength))
            revealChars(newText, from: commonLength)
        }

        previousRaw = newText

        // Timer de pausa inteligente con 3 niveles:
        // - Oración completa (punto, ?, !) → 3.5s antes de limpiar
        // - Coma o pausa natural detectada por NL → 2.5s
        // - Texto en curso (parcial) → 4.0s (más generoso, aún puede llegar más)
        let pauseInterval: Double = 3.0   // 3s de silencio antes de limpiar

        sentenceTimer = Timer.scheduledTimer(withTimeInterval: pauseInterval, repeats: false) { _ in
            Task { @MainActor in
                guard self.isActive else { return }
                // Fade suave de 0.6s antes de limpiar
                withAnimation(.easeOut(duration: 0.6)) { self.isFading = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                    self.displayedText = ""
                    self.previousRaw = ""
                    self.isFading = false
                }
            }
        }
    }

    // MARK: - Aladdin reveal
    private func revealChars(_ fullText: String, from startIndex: Int) {
        revealTimer?.invalidate()
        let chars = Array(fullText)
        guard startIndex < chars.count else { displayedText = fullText; return }
        var i = startIndex

        revealTimer = Timer.scheduledTimer(withTimeInterval: 0.035, repeats: true) { timer in
            guard i < chars.count else { timer.invalidate(); return }
            Task { @MainActor in
                self.displayedText = String(chars[0...i])
                i += 1
            }
        }
    }

    // MARK: - NaturalLanguage helpers

    /// Longitud del prefijo común entre dos strings
    private func commonPrefixLength(_ a: String, _ b: String) -> Int {
        var count = 0
        for (ca, cb) in zip(a, b) {
            if ca == cb { count += 1 } else { break }
        }
        return count
    }

    /// Detecta si el texto termina en un límite de oración (punto, ?, !, etc.)
    private func endsWithSentenceBoundary(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = trimmed
        var lastEnd = trimmed.startIndex
        tokenizer.enumerateTokens(in: trimmed.startIndex..<trimmed.endIndex) { range, _ in
            lastEnd = range.upperBound
            return true
        }
        return lastEnd == trimmed.endIndex
    }

    /// Detecta comas, punto y coma u otros separadores de cláusula
    private func endsWithPartialBoundary(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let last = trimmed.last else { return false }
        return [",", ";", ":", "—", "–"].contains(String(last))
    }

    /// Decide si hay suficiente diferencia semántica para hacer fade entre textos
    private func shouldFadeBeforeNew(old: String, new: String) -> Bool {
        guard !old.isEmpty else { return false }
        let oldWords = Set(old.lowercased().split(separator: " "))
        let newWords = Set(new.lowercased().split(separator: " "))
        let overlap = oldWords.intersection(newWords).count
        let similarity = Double(overlap) / Double(max(oldWords.count, 1))
        return similarity < 0.3 // < 30% de palabras en común → oración nueva
    }
}

// MARK: - Barras de audio (ecualizador)
struct AudioBarsView: View {
    let isActive: Bool
    let color: Color
    @State private var heights: [CGFloat] = [6, 12, 8, 14, 6]
    @State private var animating = false
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: heights[i])
                    .animation(
                        .easeInOut(duration: 0.2).delay(Double(i) * 0.05),
                        value: heights[i]
                    )
            }
        }
        .frame(height: 18)
        .onReceive(timer) { _ in
            guard isActive else { return }
            heights = (0..<5).map { _ in CGFloat.random(in: 4...16) }
        }
        .onDisappear { heights = [6, 6, 6, 6, 6] }
    }
}

// ─────────────────────────────────────────────

#Preview {
    SubtitlesView(vm: TranslationViewModel())
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
