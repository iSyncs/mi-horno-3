// ConversationView.swift
// Conversación 1 a 1 — Traducción por bloques + texto en vivo
//
// CAMBIOS v2:
//   • Mientras escucha UN lado, muestra el texto parcial en vivo en su propia área
//     para que el hablante vea que se está capturando su voz.
//   • El lado contrario muestra la traducción del bloque ANTERIOR (no palabra a palabra).
//   • Cuando el hablante termina (pausa 1.8 s o isFinal), el bloque completo se
//     traduce y aparece en el otro lado con el efecto Aladdin existente.
//   • No hay cambios en la lógica de animaciones ni en el diseño visual.

import SwiftUI
import Combine
import AVFoundation
import Speech
import Vision
import VisionKit
import Translation

// ─────────────────────────────────────────────

struct ConversationView: View {
    @EnvironmentObject var lm: LocalizationManager
    @ObservedObject var vm: TranslationViewModel
    @Environment(\.colorScheme) var scheme

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.h3BG(scheme).ignoresSafeArea()

            VStack(spacing: 0) {

                // ── ARRIBA: Español (empleado)
                // liveText:    lo que el empleado está diciendo ahora (texto parcial)
                // displayText: la traducción del bloque que acaba de decir el visitante
                //              (para que el empleado vea qué dijo el visitante)
                ConversationHalf(
                    liveText:    vm.liveSpanishText,       // retroalimentación en vivo del empleado
                    displayText: vm.translatedVisitorText, // empleado lee lo que tradujo el visitante
                    isListening: vm.spanishListening,
                    langName:    "Español",
                    langCode:    "ES",
                    color:       Color.h3Orange,
                    isFlipped:   true,
                    placeholder: "Toca para hablar",       // siempre en español, nunca traducido
                    onTap:       { vm.startSpanishListening() }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -20)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: appeared)

                // ── Divider ──
                ConversationDivider()
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)

                // ── ABAJO: Visitante (rotado 180°)
                // liveText:    lo que el visitante está diciendo ahora
                // displayText: la traducción del bloque que acaba de decir el empleado
                //              (para que el visitante lea lo que dijo el empleado)
                ConversationHalf(
                    liveText:    vm.liveVisitorText,        // retroalimentación en vivo del visitante
                    displayText: vm.translatedSpanishText,  // visitante lee lo que tradujo el empleado
                    isListening: vm.visitorListening,
                    langName:    Locale(identifier: lm.deviceLanguage).localizedString(forLanguageCode: lm.deviceLanguage) ?? lm.deviceLanguageName,
                    langCode:    lm.deviceLanguage.uppercased(),
                    color:       Color(hex: "#30D158"),
                    isFlipped:   false,
                    placeholder: lm.s(L.convTapToSpeak),   // traducido al idioma del visitante
                    onTap:       { vm.startVisitorListening() }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.15), value: appeared)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button { vm.toggleConversation() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.h3Sub(scheme))
                            .frame(width: 34, height: 34)
                            .background(Color.h3Card2(scheme))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.h3Separator(scheme), lineWidth: 1))
                    }
                    .padding(.top, 54)
                    .padding(.trailing, 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.3), value: appeared)
                }
                Spacer()
            }
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}

// MARK: - Divider
struct ConversationDivider: View {
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            Color.h3Separator(scheme).frame(height: 48)

            HStack(spacing: 12) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, Color.h3Separator(scheme)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)

                ZStack {
                    Circle()
                        .fill(Color.h3Card2(scheme))
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Color.h3Separator(scheme), lineWidth: 1))
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.h3Sub(scheme).opacity(0.6))
                }

                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.h3Separator(scheme), .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Half Panel
struct ConversationHalf: View {
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme

    let liveText: String        // texto en vivo de ESTE hablante (retroalimentación)
    let displayText: String     // traducción del OTRO hablante (lo que este lado lee)
    let isListening: Bool
    let langName: String
    let langCode: String
    let color: Color
    let isFlipped: Bool
    let placeholder: String     // texto del placeholder fijo por lado
    let onTap: () -> Void

    // Gemini ripples
    @State private var ripple1: CGFloat = 0
    @State private var ripple2: CGFloat = 0
    @State private var ripple3: CGFloat = 0
    @State private var geminiPhase: CGFloat = 0
    @State private var geminiScale: CGFloat = 1.0
    @State private var buttonScale: CGFloat = 1.0

    // Reveal letra a letra del texto traducido (bloque completo del otro lado)
    @State private var displayedText: String = ""
    @State private var revealTimer: Timer? = nil

    var body: some View {
        ZStack {
            // Glow radial al escuchar
            if isListening {
                RadialGradient(
                    colors: [color.opacity(scheme == .dark ? 0.10 : 0.06), .clear],
                    center: .center, startRadius: 10, endRadius: 250
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: isListening)
            }

            VStack(spacing: 0) {
                badgeView
                    .padding(.top, 28)

                textArea
                    .padding(.top, 16)

                micButton
                    .padding(.top, 20)
                    .padding(.bottom, 28)
            }
            .rotationEffect(isFlipped ? .degrees(180) : .zero)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.3), value: isListening)
        .onChange(of: isListening) { listening in
            if listening {
                // Al empezar a escuchar: limpia el texto en vivo anterior
                displayedText = ""
                ripple1 = 0; ripple2 = 0; ripple3 = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    ripple1 = 1; ripple2 = 1; ripple3 = 1
                }
                geminiPhase = 0
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    geminiPhase = 360
                }
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    geminiScale = 1.07
                }
            } else {
                ripple1 = 0; ripple2 = 0; ripple3 = 0
                geminiPhase = 0
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    geminiScale = 1.0
                }
            }
        }
        // Cuando llega una traducción completa del otro lado → efecto Aladdin
        .onChange(of: displayText) { newText in
            guard !newText.isEmpty else { displayedText = ""; return }
            if newText.hasPrefix(displayedText) {
                revealChars(newText, from: displayedText.count)
            } else {
                displayedText = ""
                revealChars(newText, from: 0)
            }
        }
    }

    // MARK: - Subviews

    private var badgeView: some View {
        HStack(spacing: 6) {
            Text(langCode)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(color)
            Text("·")
                .foregroundColor(Color.h3Sub(scheme).opacity(0.4))
            // Nombre del idioma con mayúscula inicial
            Text(langName.prefix(1).uppercased() + langName.dropFirst())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.h3Sub(scheme))
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(isListening ? 0.12 : 0.07)))
        .overlay(Capsule().stroke(color.opacity(isListening ? 0.45 : 0.18), lineWidth: 1))
        .animation(.easeInOut(duration: 0.3), value: isListening)
    }

    /// Área de texto con dos capas:
    ///   1. Si está escuchando y hay texto parcial → muestra liveText en gris tenue
    ///      (retroalimentación para el hablante: "te estoy entendiendo")
    ///   2. Si hay traducción del otro lado → la muestra con efecto Aladdin
    private var textArea: some View {
        ZStack {
            // Capa 1: texto en vivo del hablante actual (solo visible cuando escucha)
            if isListening && !liveText.isEmpty {
                Text(liveText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }
            // Capa 2: traducción completa del otro hablante
            else if !displayedText.isEmpty {
                ScrollView(showsIndicators: false) {
                    Text(displayedText)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.h3Text(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 8)
                }
                .transition(.opacity)
            }
            // Capa 3: placeholder
            else {
                Text(isListening ? "…" : placeholder)
                    .font(.system(size: 14))
                    .foregroundColor(Color.h3Sub(scheme).opacity(0.4))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .animation(.easeInOut(duration: 0.2), value: isListening)
        .animation(.easeInOut(duration: 0.2), value: liveText.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: displayedText.isEmpty)
    }

    private var micButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { buttonScale = 0.85 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { buttonScale = 1.0 }
            }
            onTap()
        }) {
            ZStack {
                if isListening {
                    Circle()
                        .stroke(color.opacity(0.25 * (1 - ripple1)), lineWidth: 1.5)
                        .frame(width: 58 + ripple1 * 44, height: 58 + ripple1 * 44)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: ripple1)
                    Circle()
                        .stroke(color.opacity(0.18 * (1 - ripple2)), lineWidth: 1)
                        .frame(width: 58 + ripple2 * 62, height: 58 + ripple2 * 62)
                        .animation(.easeOut(duration: 1.5).delay(0.4).repeatForever(autoreverses: false), value: ripple2)
                    Circle()
                        .stroke(color.opacity(0.10 * (1 - ripple3)), lineWidth: 0.5)
                        .frame(width: 58 + ripple3 * 80, height: 58 + ripple3 * 80)
                        .animation(.easeOut(duration: 1.5).delay(0.8).repeatForever(autoreverses: false), value: ripple3)
                }

                Circle()
                    .fill(
                        isListening
                        ? AnyShapeStyle(AngularGradient(
                            colors: [color, color.opacity(0.6), color],
                            center: .center,
                            angle: .degrees(geminiPhase)
                        ))
                        : AnyShapeStyle(color.opacity(scheme == .dark ? 0.12 : 0.10))
                    )
                    .frame(width: 58, height: 58)
                    .overlay(Circle().stroke(color.opacity(isListening ? 0 : 0.35), lineWidth: 1.5))
                    .shadow(color: isListening ? color.opacity(0.45) : .clear, radius: 16)
                    .scaleEffect(geminiScale)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isListening)

                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isListening ? .white : color)
                    .animation(.easeInOut(duration: 0.2), value: isListening)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(buttonScale)
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
}

// ─────────────────────────────────────────────

#Preview {
    ConversationView(vm: TranslationViewModel())
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
