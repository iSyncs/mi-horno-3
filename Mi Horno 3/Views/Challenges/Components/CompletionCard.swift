// CompletionCard.swift
// Pantalla de resultados al completar todos los desafíos

import SwiftUI

// MARK: - Completion Card
struct CompletionCard: View {
    let title: String
    let subtitle: String
    let score: Int
    let total: Int
    let buttonTitle: String
    let action: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 44))
                .foregroundColor(.h3Orange)
                .shadow(color: Color.h3Orange.opacity(0.4), radius: 12)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(Color.h3Text(scheme))
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(Color.h3Sub(scheme))
            }

            ZStack {
                Circle()
                    .stroke(Color.h3Card2(scheme), lineWidth: 10)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: Double(score) / Double(total))
                    .stroke(Color.h3Orange,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                    .animation(.spring(response: 0.8), value: score)
                Text("\(Int(Double(score) / Double(total) * 100))%")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(Color.h3Text(scheme))
            }

            Button(action: action) {
                Label(buttonTitle, systemImage: "arrow.counterclockwise")
            }
            .h3OrangeButton()
        }
        .padding(24)
        .h3Card()
        .padding(.top, 8)
    }
}


#Preview {
    return CompletionCard(
        title: "Desafío completado",
        subtitle: "4 de 5 respuestas correctas",
        score: 4,
        total: 5,
        buttonTitle: "Volver a intentar",
        action: {}
    )
        .environmentObject(LocalizationManager.shared)
        .padding()
        .preferredColorScheme(.dark)
        .background(Color.h3Black)
}
