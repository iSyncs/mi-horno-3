import SwiftUI

struct CameraPreparationView: View {
    let challenge: ChallengeDefinition
    @EnvironmentObject var vm: ChallengesViewModel
    @Environment(\.colorScheme) var scheme
    
    @State private var PROGRESO_BORDE: CGFloat = 0.0
    @State private var BOTON_PRESIONADO: Bool = false
    @State private var ANIMACION_COMPLETADA: Bool = false
    
    var body: some View {
        ZStack {
            // Fondo: Degradado blanco limpio
            LinearGradient(
                colors: [Color.white, Color(hex: "#F5F5F7")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Mantenemos la animación del borde para el feedback del long press
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .trim(from: 0, to: PROGRESO_BORDE)
                .stroke(
                    Color(hex: "#F06400"),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .padding(8)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar para botón atrás
                HStack {
                    Button {
                        vm.leaveFlow()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 42, height: 42)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Tarjeta Central (Glassmorphism)
                VStack(spacing: 20) {
                    // Icono cronómetro
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(hex: "#F06400").opacity(0.15), radius: 20, y: 10)
                        
                        Image(systemName: "stopwatch.fill")
                            .font(.system(size: 38))
                            .foregroundColor(Color(hex: "#F06400"))
                    }
                    .padding(.bottom, 8)
                    
                    Text("Desafío\nContrarreloj")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "#2C2C2C"))
                        .multilineTextAlignment(.center)
                    
                    Text("Este desafío requiere tu cámara y es por tiempo limitado. La aplicación te indicará qué estructura buscar una vez que inicies.")
                        .font(.system(size: 17, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: "#595959"))
                        .lineSpacing(6)
                        .padding(.horizontal, 8)
                    
                    // Sección de Aviso (Nota)
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Color.black.opacity(0.35))
                        Text("Prepárate para moverte rápido")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.black.opacity(0.45))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 44)
                .background(.ultraThinMaterial)
                .background(Color.white.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 30, y: 15)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Botón de Acción (CTA)
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FF7A00"), Color(hex: "#E05D00")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 64)
                        .shadow(color: Color(hex: "#F06400").opacity(BOTON_PRESIONADO ? 0.2 : 0.45), radius: BOTON_PRESIONADO ? 6 : 16, y: BOTON_PRESIONADO ? 4 : 8)
                        .scaleEffect(BOTON_PRESIONADO ? 0.94 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: BOTON_PRESIONADO)
                    
                    Text("Mantener para Iniciar")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !BOTON_PRESIONADO {
                                BOTON_PRESIONADO = true
                                withAnimation(.linear(duration: 2.0)) {
                                    PROGRESO_BORDE = 1.0
                                }
                            }
                        }
                        .onEnded { _ in
                            if PROGRESO_BORDE < 1.0 {
                                BOTON_PRESIONADO = false
                                withAnimation(.easeOut(duration: 0.3)) {
                                    PROGRESO_BORDE = 0.0
                                }
                            }
                        }
                )
                .onChange(of: PROGRESO_BORDE) { newValue in
                    if newValue >= 1.0 && !ANIMACION_COMPLETADA {
                        ANIMACION_COMPLETADA = true
                        let GENERADOR_IMPACTO = UIImpactFeedbackGenerator(style: .heavy)
                        GENERADOR_IMPACTO.impactOccurred()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            vm.selectFlow(.camera(challenge))
                        }
                    }
                }
            }
        }
    }
}
