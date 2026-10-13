// H3TextField.swift
// Campo de texto reutilizable con icono y toggle de contraseña

import SwiftUI

struct H3TextField: View {
    let placeholder: String
    let icon: String
    @Binding var text: String
    let isSecure: Bool
    @Environment(\.colorScheme) var scheme
    @State private var showPwd = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 15))
                .foregroundColor(Color.h3Sub(scheme)).frame(width: 20)

            if isSecure && !showPwd {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 15)).foregroundColor(Color.h3Text(scheme))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 15)).foregroundColor(Color.h3Text(scheme))
            }
            if isSecure {
                Button { showPwd.toggle() } label: {
                    Image(systemName: showPwd ? "eye.slash" : "eye")
                        .font(.system(size: 14)).foregroundColor(Color.h3Sub(scheme))
                }
            }
        }
        .padding(.horizontal, 16).frame(height: 54)
        .background(Color.h3Card(scheme)).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.h3Separator(scheme), lineWidth: 1))
    }
}


#Preview {
    VStack(spacing: 12) {
        H3TextField(placeholder: "Correo electrónico", icon: "envelope.fill",
                    text: .constant(""), isSecure: false)
        H3TextField(placeholder: "Contraseña", icon: "lock.fill",
                    text: .constant(""), isSecure: true)
    }
    .padding()
    .preferredColorScheme(.dark)
    .background(Color.h3Black)
}
