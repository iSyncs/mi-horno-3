import SwiftUI

struct PERFILAMIENTO_VIEW: View {
    @AppStorage("EDAD_USUARIO") var EDAD_USUARIO: Int = 18
    @AppStorage("GENERO_USUARIO") var GENERO_USUARIO: String = "Prefiero no decirlo"
    @AppStorage("DISCAPACIDAD_MOTRIZ") var DISCAPACIDAD_MOTRIZ: Bool = false
    @AppStorage("PERFIL_COMPLETADO") var PERFIL_COMPLETADO: Bool = false
    
    @Environment(\.colorScheme) var scheme
    
    var body: some View {
        ZStack {
            // Fondo oscuro para destacar la tarjeta
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Cabecera
                VStack(spacing: 8) {
                    Text("Personaliza tus Desafíos")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(Color.h3Text(scheme))
                        .multilineTextAlignment(.center)
                    
                    Text("Ayúdanos a adaptar las preguntas y misiones del Horno 3 para ti.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.h3Sub(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                .padding(.top, 10)
                
                // Formulario
                VStack(spacing: 20) {
                    // EDAD_USUARIO
                    HStack {
                        Text("Edad")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.h3Text(scheme))
                        Spacer()
                        Stepper("\(EDAD_USUARIO) años", value: $EDAD_USUARIO, in: 4...100)
                            .labelsHidden()
                        Text("\(EDAD_USUARIO)")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(Color.h3Orange)
                            .frame(width: 36, alignment: .trailing)
                    }
                    .padding()
                    .background(Color.h3BG(scheme).opacity(0.6))
                    .cornerRadius(14)
                    
                    // GENERO_USUARIO
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Género")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.h3Sub(scheme))
                            .padding(.leading, 4)
                        
                        Picker("Género", selection: $GENERO_USUARIO) {
                            Text("Femenino").tag("Femenino")
                            Text("Masculino").tag("Masculino")
                            Text("Otro").tag("Otro")
                            Text("Prefiero no decirlo").tag("Prefiero no decirlo")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.h3BG(scheme).opacity(0.6))
                        .cornerRadius(14)
                    }
                    
                    // DISCAPACIDAD_MOTRIZ
                    Toggle(isOn: $DISCAPACIDAD_MOTRIZ) {
                        Text("Requiero desafíos con movilidad reducida")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.h3Text(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.h3Orange))
                    .padding()
                    .background(Color.h3BG(scheme).opacity(0.6))
                    .cornerRadius(14)
                }
                
                // Botón
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        PERFIL_COMPLETADO = true
                    }
                }) {
                    Text("Guardar y Comenzar")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.h3Orange)
                        .cornerRadius(16)
                        .shadow(color: Color.h3Orange.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(28)
            .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 15)
            .padding(24)
        }
    }
}
