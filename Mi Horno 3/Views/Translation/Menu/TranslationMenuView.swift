// TranslationMenuView.swift
// Menú principal con las tres tarjetas de funcionalidades

import SwiftUI
import Combine
import AVFoundation
import Speech
import Vision
import VisionKit
import Translation

// ─────────────────────────────────────────────

// MARK: - Menu
// ─────────────────────────────────────────────
struct TranslationMenuView: View {
    @EnvironmentObject var lm: LocalizationManager
    @ObservedObject var vm: TranslationViewModel
    @Environment(\.colorScheme) var scheme

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 25) {  // ← separación entre tarjetas

            // ── Header ──
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lm.s(L.translationTitle))
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(Color.h3Text(scheme))
                    Text(lm.s(L.translationSubtitle))
                        .font(.system(size: 13))
                        .foregroundColor(Color.h3Sub(scheme))
                }
                Spacer()
                HStack(spacing: 5) {
                    Text("ES")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color.h3Text(scheme))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color.h3Sub(scheme))
                    Text(lm.deviceLanguage.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color.h3Text(scheme))
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.h3Card2(scheme))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.h3Separator(scheme), lineWidth: 1)
                )
                .padding(.top, 5)
            }
            .padding(.horizontal, 5)
            .padding(.top, 60)  // ← espacio arriba del título

            // ── Cards ──
            BigFeatureCard(
                icon: "captions.bubble.fill",
                title: lm.s(L.translationSubtitlesTitle),
                description: lm.s(L.translationSubtitlesSubtitle),
                color: Color.h3Orange,
                bgColors: [Color(hex: "#FF6B35"), Color(hex: "#E8501A")],
                action: { vm.toggleSubtitles() }
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05), value: appeared)

            BigFeatureCard(
                icon: "text.viewfinder",
                title: lm.s(L.translationVisualTitle),
                description: lm.s(L.translationVisualSubtitle),
                color: Color(hex: "#0A84FF"),
                bgColors: [Color(hex: "#2196F3"), Color(hex: "#0A5FCC")],
                action: { vm.toggleVisual() }
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.12), value: appeared)

            BigFeatureCard(
                icon: "person.2.wave.2.fill",
                title: lm.s(L.translationConvTitle),
                description: lm.s(L.translationConvSubtitle),
                color: Color(hex: "#30D158"),
                bgColors: [Color(hex: "#34C759"), Color(hex: "#1A8C35")],
                action: { vm.toggleConversation() }
            )
            
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.19), value: appeared)
            
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 50)  // ← AJUSTA ESTE para que no tape el tab bar
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}

struct BigFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let bgColors: [Color]
    let action: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Colored top section
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: bgColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: icon)
                        .font(.system(size: 80, weight: .black))
                        .foregroundColor(.white.opacity(0.07))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                        .offset(x: -20, y: 7)
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        Text(title)
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
                .frame(maxHeight: .infinity)  // ← parte de color, crece proporcionalmente

                // Description bottom section
                HStack(alignment: .center) {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(Color.h3Sub(scheme))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 15)
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 15)  // ← altura del área de descripción
                .background(Color.h3Card(scheme))
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: color.opacity(0.2), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // ← cada tarjeta toma su parte igual
    }
}

// ─────────────────────────────────────────────

#Preview {
    TranslationMenuView(vm: TranslationViewModel())
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
