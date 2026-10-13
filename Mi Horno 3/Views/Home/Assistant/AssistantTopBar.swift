// AssistantTopBar.swift

import SwiftUI

struct AssistantTopBar: View {
    @ObservedObject var vm: AssistantViewModel
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // Botón cerrar
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.h3Text(scheme))
                    .frame(width: 36, height: 36)
                    .background(Color.h3Card2(scheme))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.h3Separator(scheme), lineWidth: 1))
            }

            Spacer()

            // Título centro
            VStack(spacing: 3) {
                HStack(spacing: 6) {
                    // Indicador de estado vivo
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                        .shadow(color: statusColor.opacity(0.6), radius: 4)
                    Text(lm.s(L.assistantTitle))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.h3Text(scheme))
                }
                Text(stateLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.h3Sub(scheme))
            }

            Spacer()

            // Placeholder para centrar el título
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 16)
    }

    private var stateLabel: String {
        switch vm.state {
        case .downloadingModel(let p): return "Descargando… \(Int(p * 100))%"
        case .loadingModel:            return "Iniciando asistente…"
        case .idle:                    return lm.s(L.assistantStateIdle)
        case .listening:               return lm.s(L.assistantStateListening)
        case .readyToSend:             return lm.s(L.assistantStateReady)
        case .processing:              return lm.s(L.assistantStateProcessing)
        case .responding:              return lm.s(L.assistantStateResponding)
        }
    }

    private var statusColor: Color {
        switch vm.state {
        case .idle, .loadingModel, .downloadingModel: return Color(hex: "#30D158")
        case .listening:   return .red
        case .readyToSend: return .h3Orange
        case .processing:  return .h3Orange
        case .responding:  return Color(hex: "#30D158")
        }
    }
}

#Preview {
    AssistantTopBar(vm: AssistantViewModel(), dismiss: {})
        .environmentObject(LocalizationManager.shared)
        .background(Color.h3BG(.dark))
}
