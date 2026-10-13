// AssistantView.swift

import SwiftUI

struct AssistantView: View {
    @EnvironmentObject var lm: LocalizationManager
    @StateObject private var vm = AssistantViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            // Fondo adaptativo
            Color.h3BG(scheme).ignoresSafeArea()

            // Textura sutil — puntos industriales de fondo
            GeometryReader { geo in
                Canvas { ctx, size in
                    let spacing: CGFloat = 28
                    let cols = Int(size.width / spacing) + 1
                    let rows = Int(size.height / spacing) + 1
                    for row in 0..<rows {
                        for col in 0..<cols {
                            let x = CGFloat(col) * spacing
                            let y = CGFloat(row) * spacing
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                                with: .color(scheme == .dark
                                    ? Color.white.opacity(0.04)
                                    : Color.black.opacity(0.04))
                            )
                        }
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                AssistantTopBar(vm: vm, dismiss: { dismiss() })
                AssistantChatArea(vm: vm)
                AssistantFABRow(vm: vm)
            }
        }
        .onAppear { vm.requestPermissions() }
    }
}

#Preview {
    AssistantView().environmentObject(LocalizationManager.shared)
}
