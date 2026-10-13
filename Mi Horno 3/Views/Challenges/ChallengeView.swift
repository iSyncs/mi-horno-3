import SwiftUI

struct ChallengeView: View {
    @ObservedObject var viewModel: ChallengesViewModel
    
    var body: some View {
        ZStack {
            // Fondo con desenfoque dinámico (Liquid Glass Base)
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                headerView
                
                // Verificamos si la zona actual está completada al 100%
                if viewModel.progressForZone(viewModel.selectedZone) >= 1.0 {
                    victoryView
                } else {
                    challengesListView
                }
            }
            .padding()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Desafíos de Zona")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.bottom)
    }
    
    private var challengesListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filtramos los desafíos de la zona seleccionada
                let zoneChallenges = viewModel.challenges.filter { $0.zone == viewModel.selectedZone }
                
                ForEach(zoneChallenges) { challenge in
                    ChallengeRow(challenge: challenge, isCompleted: viewModel.completedChallengeIDs.contains(challenge.id)) {
                        // Al tocar, activamos el flujo correspondiente
                        if challenge.kind == .quiz {
                            viewModel.selectFlow(.quiz(challenge))
                        } else {
                            viewModel.startNewCameraMission(for: challenge.zone)
                        }
                    }
                }
            }
        }
    }
    
    private var victoryView: some View {
        VStack(spacing: 25) {
            Spacer()
            Image(systemName: "crown.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow.gradient)
            
            Text("¡Aventurero Máximo de la Zona!")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Text("Has conquistado todos los secretos industriales de esta sección.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
}

struct ChallengeRow: View {
    let challenge: ChallengeDefinition
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(challenge.kind == .quiz ? "Trivia" : "Misión de Cámara")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundColor(isCompleted ? .green : .white.opacity(0.4))
            }
            .padding()
            // EFECTO LIQUID GLASS
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(isCompleted)
        .opacity(isCompleted ? 0.6 : 1)
    }
}
