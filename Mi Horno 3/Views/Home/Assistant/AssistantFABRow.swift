// AssistantFABRow.swift

import SwiftUI

struct AssistantFABRow: View {
    @ObservedObject var vm: AssistantViewModel
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme

    @State private var buttonScale: CGFloat = 1.0
    @State private var ripple: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // ── Transcripción en vivo ─────────────────────────────────
            if !vm.currentTranscript.isEmpty {
                HStack(spacing: 10) {
                    Circle()
                        .fill(.red)
                        .frame(width: 7, height: 7)

                    Text(vm.currentTranscript)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.h3Text(scheme))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.h3Card(scheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // ── Botón FAB ─────────────────────────────────────────────
            ZStack {
                // Ripple cuando escucha
                if vm.state == .listening {
                    Circle()
                        .stroke(Color.red.opacity(0.25 * (1 - ripple)), lineWidth: 1.5)
                        .frame(width: 72 + ripple * 60, height: 72 + ripple * 60)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false),
                                   value: ripple)
                }

                if vm.shouldShowCancel {
                    // Botón cancelar a la izquierda
                    HStack {
                        Button { vm.cancelTapped() } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Cancelar")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(Color.h3Text(scheme))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.h3Card2(scheme))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.h3Separator(scheme), lineWidth: 1))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 36)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                // Botón principal
                Button { handleFabTap() } label: {
                    ZStack {
                        Circle()
                            .fill(fabBackground)
                            .frame(width: 72, height: 72)
                            .shadow(color: fabShadow, radius: 16, y: 6)

                        if vm.state == .processing {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.1)
                        } else {
                            Image(systemName: vm.fabIcon)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .scaleEffect(buttonScale)
                .disabled(vm.state == .processing ||
                          vm.state == .downloadingModel(0) ||
                          vm.state == .loadingModel)
            }
        }
        .padding(.bottom, 44)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: vm.shouldShowCancel)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: vm.currentTranscript.isEmpty)
        .onAppear {
            if vm.state == .listening { ripple = 1 }
        }
        .onChange(of: vm.state) { s in
            if s == .listening {
                ripple = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { ripple = 1 }
            } else {
                ripple = 0
            }
        }
    }

    private func handleFabTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { buttonScale = 0.88 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { buttonScale = 1.0 }
        }
        vm.fabTapped()
    }

    private var fabBackground: some ShapeStyle {
        switch vm.state {
        case .listening:
            return AnyShapeStyle(Color.red)
        case .readyToSend:
            return AnyShapeStyle(Color.h3Orange)
        case .responding:
            return AnyShapeStyle(Color(hex: "#30D158"))
        default:
            return AnyShapeStyle(Color.h3Orange)
        }
    }

    private var fabShadow: Color {
        switch vm.state {
        case .listening:  return .red.opacity(0.4)
        case .responding: return Color(hex: "#30D158").opacity(0.4)
        default:          return Color.h3Orange.opacity(0.4)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        AssistantFABRow(vm: AssistantViewModel())
            .environmentObject(LocalizationManager.shared)
    }
    .background(Color.h3BG(.dark))
}
