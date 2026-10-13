// SensoryMessageBubble.swift
import SwiftUI

struct SensoryMessageBubble: View {
    let message: SensoryMessage
    @Environment(\.colorScheme) var scheme
    @EnvironmentObject var lm: LocalizationManager

    private let accent = Color(hex: "#BF5AF2")

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {

            if message.role == .assistant {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.14))
                        .frame(width: 30, height: 30)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 13))
                        .foregroundColor(accent)
                }
                .alignmentGuide(.bottom) { d in d[.bottom] }
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {

                // Burbuja principal
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(bubbleTextColor)
                    .lineSpacing(3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(bubbleBackground)
                    .cornerRadius(20, corners: bubbleCorners)
                    .shadow(
                        color: message.role == .user
                            ? accent.opacity(0.3)
                            : Color.black.opacity(scheme == .dark ? 0.18 : 0.05),
                        radius: 8, x: 0, y: 3
                    )

                // Pill de nivel sensorial — usa lm.s() sobre la clave L almacenada en level
                if message.role == .assistant, let level = message.level {
                    levelPill(level)
                }

                // Card de consejo
                if message.role == .assistant, let tip = message.tip {
                    tipCard(tip)
                }
            }

            Spacer(minLength: 52)
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    // MARK: - Level pill
    // `level` ya es una clave L (ej: L.sensoryLevelTranquila = "tranquila")
    // lm.s() la traduce al idioma del dispositivo
    private func levelPill(_ level: String) -> some View {
        let color = levelColor(level)
        let icon  = levelIcon(level)
        let label = lm.s(L.sensoryIntensity) + " " + lm.s(level)

        return HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        .clipShape(Capsule())
    }

    // MARK: - Tip card
    private func tipCard(_ tip: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accent.opacity(0.14))
                    .frame(width: 28, height: 28)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(accent)
            }
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                // "Consejo" traducido
                Text(lm.s(L.sensoryTip).uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(accent)
                    .tracking(0.3)
                // El tip ya llega traducido desde el ViewModel
                Text(tip)
                    .font(.system(size: 12))
                    .foregroundColor(Color.h3Sub(scheme))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accent.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accent.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private var bubbleBackground: Color {
        message.role == .user ? accent : Color.h3Card(scheme)
    }

    private var bubbleTextColor: Color {
        message.role == .user ? .white : Color.h3Text(scheme)
    }

    private var bubbleCorners: UIRectCorner {
        message.role == .user
            ? [.topLeft, .topRight, .bottomLeft]
            : [.topLeft, .topRight, .bottomRight]
    }

    // Compara contra las claves L (que son los strings en español)
    private func levelColor(_ level: String) -> Color {
        switch level {
        case L.sensoryLevelTranquila: return Color(hex: "#30D158")
        case L.sensoryLevelModerada:  return Color(hex: "#FF9F0A")
        case L.sensoryLevelIntensa:   return Color(hex: "#FF453A")
        default:                       return Color.h3Sub(scheme)
        }
    }

    private func levelIcon(_ level: String) -> String {
        switch level {
        case L.sensoryLevelTranquila: return "checkmark.circle.fill"
        case L.sensoryLevelModerada:  return "exclamationmark.circle.fill"
        case L.sensoryLevelIntensa:   return "ear.trianglebadge.exclamationmark.fill"
        default:                       return "circle.fill"
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 14) {
            SensoryMessageBubble(message: SensoryMessage(
                role: .user,
                text: "¿Hay mucho ruido en la Sala del Alto Horno?",
                tip: nil, level: nil
            ))
            SensoryMessageBubble(message: SensoryMessage(
                role: .assistant,
                text: "Sí, la Sala del Alto Horno tiene ruido alto con grabaciones de maquinaria pesada en loop. La iluminación es tenue y dramática.",
                tip: "Considera usar audífonos de reducción de ruido antes de entrar.",
                level: L.sensoryLevelIntensa
            ))
            SensoryMessageBubble(message: SensoryMessage(
                role: .assistant,
                text: "La Galería de la Historia del Acero es la sala más tranquila.",
                tip: "Ideal para empezar la visita o para hacer una pausa.",
                level: L.sensoryLevelTranquila
            ))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
    .environmentObject(LocalizationManager.shared)
    .preferredColorScheme(.dark)
    .background(Color.h3Black)
}
